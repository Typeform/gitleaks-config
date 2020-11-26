if id, password := os.Getenv("AWS_ACCESS_KEY_ID"), os.Getenv("AWS_SECRET_ACCESS_KEY"); len(id) > 0 && len(sak) > 0 {
	cred = credentials.NewStaticCredentials(id, sak, "")
}
