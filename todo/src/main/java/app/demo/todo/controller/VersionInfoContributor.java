package app.demo.todo.controller;

import org.springframework.boot.actuate.info.Info;
import org.springframework.boot.actuate.info.InfoContributor;
import org.springframework.stereotype.Component;
import app.demo.todo.AppConfig;

@Component
public class VersionInfoContributor implements InfoContributor {
    @Override
    public void contribute(Info.Builder builder) {

        builder.withDetail("version", new AppConfig().getVersion());
    }
}