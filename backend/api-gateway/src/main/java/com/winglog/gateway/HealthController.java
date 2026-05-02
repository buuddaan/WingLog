package com.winglog.gateway;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController; //Från SpringBoot som låter oss annotera den som RestController (använd som REST-anrop) /EF

@RestController//Säger till Spring att "kolla i denna" när det kommer in REST-anrop /EF

public class HealthController {

    //Om vi anropar denna API får vi tillbaka att den lever, så kan vi testa att tjänsten är up and running /EF
    @GetMapping("/health")
    public String health() {
        return "Gateway is up and running";
    }
}
