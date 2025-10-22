package com.engagepoint.content_scheduler;

import org.springframework.context.annotation.Bean;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import engagepoint.content_scheduler.service.FirebaseManager;
import engagepoint.content_scheduler.service.ContentScheduler;

@SpringBootApplication
public class ContentSchedulerApplication {
	public static void main(String[] args) {
		SpringApplication.run(ContentSchedulerApplication.class, args);
	}

	@Bean
	public ContentScheduler contentScheduler() {
		return new ContentScheduler();
	}
}
