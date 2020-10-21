package com.ctrip.framework.apollo.use.cases.spring.boot.logger;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JavaConfigBean {
    @Value("${timeout:20}")
    private String timeout;

    public String getTimeout() {
        return timeout;
    }
}
