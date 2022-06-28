package main

import (
	"fmt"
)

func main() {
	var variables map[string]int {'a': 1, 'b': 2}
	
	for key := range variables {
		// test that gitleaks does not detect the following line as a hardcoded variable
		if key == "some_condition" || key == "different_condition" {
			fmt.Println(key)
		}
	}
}
