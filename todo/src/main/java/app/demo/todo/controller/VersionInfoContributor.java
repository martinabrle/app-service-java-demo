package app.demo.todo.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.actuate.info.Info;
import org.springframework.boot.actuate.info.InfoContributor;
import org.springframework.stereotype.Component;
import app.demo.todo.AppConfig;

@Component
public class VersionInfoContributor implements InfoContributor {
    @Autowired
    private AppConfig appConfig;

    @Override
    public void contribute(Info.Builder builder) {

        builder.withDetail("version", appConfig.getVersion());
    }
}