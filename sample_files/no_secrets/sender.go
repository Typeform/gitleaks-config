collectorErr := collector.Increment("deliveries_count", metric.Tag{Key: "success", Value: delivery.IsSuccessful()}, metric.Tag{Key: "status_code", Value: strconv.Itoa(delivery.Status)})
if collectorErr != nil {
	logrus.Errorf("collector error: %s", collectorErr)
}
collectorErr = collector.Histogram("webhook_request_duration", delivery.Stats().WebhookRequestDuration.Seconds(), metric.Tag{Key: "success", Value: delivery.IsSuccessful()})
if collectorErr != nil {
	logrus.Errorf("collector error: %s", collectorErr)
}
