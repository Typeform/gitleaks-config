package sender

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/Typeform/brownie/composer"
	"github.com/Typeform/brownie/log"
	"github.com/Typeform/brownie/models"
	"github.com/Typeform/brownie/models/webhooks"
	"github.com/Typeform/x/metric"
	"github.com/sirupsen/logrus"
)

//go:generate moq -out sender_mock.go . Sender

type Sender interface {
	SendWebhook(webhook *models.Webhook, event *webhooks.Event, delivery *models.Delivery, collector metric.Collector) (*models.Delivery, error)
}

// Sender is a wrapper for a postClient.
type sender struct {
	insecureClient *postClient
	secureClient   *postClient
}

// EncodeError is a error type for encoding errors.
type EncodeError struct {
	error
}

// EmptyURLError is a error that is returned when a webhook is configured with an empty URL.
type EmptyURLError struct {
	error
}

// NewSender returns a new sender.
func NewSender(tr *http.Transport) *sender {
	insecureTransport := *tr
	insecureTransport.TLSClientConfig = &tls.Config{
		InsecureSkipVerify: true,
	}

	secureTransport := *tr
	secureTransport.TLSClientConfig = &tls.Config{
		MinVersion: tls.VersionTLS12,
	}

	return &sender{
		insecureClient: newBasicClient(&insecureTransport),
		secureClient:   newBasicClient(&secureTransport),
	}
}

// SendWebhook sends actual HTTP request and handles response parsing.
//
// TODO: now function returns delivery and attempt objects, but attempt
// will be removed as soon as delivery functionality superseed it.
func (s *sender) SendWebhook(webhook *models.Webhook, event *webhooks.Event, delivery *models.Delivery, collector metric.Collector) (*models.Delivery, error) {

	// Don't try to send webhooks to empty urls
	url, err := url.QueryUnescape(webhook.URL)
	if err != nil {
		log.SenderInfo("Could not urldecode", err)
		url = webhook.URL
	}
	url = strings.TrimSpace(url)
	if url == "" {
		err = EmptyURLError{fmt.Errorf("Empty URL for webhook")}
		log.SenderInfo("Not sending webhook to empty URL", err)
		return nil, err
	}

	var buf bytes.Buffer
	if err := encodeWebhook(&buf, webhook, event); err != nil {
		return nil, EncodeError{fmt.Errorf("encode webhook: %v", err)}
	}

	client := s.getClient(webhook.VerifySSL)
	requestStartTime := time.Now()

	deliveryError := client.send(delivery, webhook.URL, webhook.Secret, &buf)

	requestDuration := time.Since(requestStartTime)
	stats := delivery.Stats()
	stats.WebhookRequestDuration = requestDuration
	delivery.SetStats(stats)

	collectorErr := collector.Increment("deliveries_count", metric.Tag{Key: "success", Value: delivery.IsSuccessful()}, metric.Tag{Key: "status_code", Value: strconv.Itoa(delivery.Status)})
	if collectorErr != nil {
		logrus.Errorf("collector error: %s", collectorErr)
	}
	collectorErr = collector.Histogram("webhook_request_duration", delivery.Stats().WebhookRequestDuration.Seconds(), metric.Tag{Key: "success", Value: delivery.IsSuccessful()})
	if collectorErr != nil {
		logrus.Errorf("collector error: %s", collectorErr)
	}

	if deliveryError != nil {
		log.WebhookTrace(delivery, webhook, err)
		return delivery, fmt.Errorf("POST request: %s", err)
	}
	log.WebhookTrace(delivery, webhook, nil)

	return delivery, nil
}

func (s *sender) getClient(verifySSL *bool) *postClient {
	if verifySSL == nil || *verifySSL == true {
		return s.secureClient
	}

	return s.insecureClient
}

// encodeWebhooks serializes webhook in a proper output format.
func encodeWebhook(buf io.Writer, webhook *models.Webhook, event *webhooks.Event) error {
	enc := json.NewEncoder(buf)
	// avoids replacement of `&` with `\u0026` in URLs
	enc.SetEscapeHTML(false)

	if webhook.IsZapier() {
		zapier, err := composer.WebhookEventToZapier(event)
		if err != nil {
			return fmt.Errorf("convert to Zapier: %s", err)
		}
		return enc.Encode(zapier)
	}

	return enc.Encode(event)
}
