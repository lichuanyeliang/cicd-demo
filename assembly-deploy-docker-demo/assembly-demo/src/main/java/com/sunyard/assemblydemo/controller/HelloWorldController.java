package com.sunyard.assemblydemo.controller;

import lombok.extern.log4j.Log4j2;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

@Log4j2
@Controller
public class HelloWorldController {


    @RequestMapping("sayHello")
    @ResponseBody
    public String sayHello() {
        log.info("request hello.......");
        return "hello";
    }
}
