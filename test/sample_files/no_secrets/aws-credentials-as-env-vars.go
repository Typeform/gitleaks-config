if key, password := os.Getenv("AWS_ACCESS_KEY_ID"), os.Getenv("AWS_SECRET_ACCESS_KEY"); len(key) > 0 && len(password) > 0 {
	cred := credentials.NewStaticCredentials(key, password, "")
	cred = credentials.NewStaticCredentials(id, sak, "")
}
