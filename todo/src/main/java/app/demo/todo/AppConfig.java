package app.demo.todo;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import app.demo.todo.utils.AppLogger;

@Component
@ConfigurationProperties(prefix = "app.demo.todo")
public class AppConfig {
    public static final AppLogger LOGGER = new AppLogger(AppConfig.class);

    private String loadDemoData = "false";
    private String debugAuthToken = "false";
    private String environment = "Unknown";

    public void setLoadDemoData(String loadDemoData) {
        this.loadDemoData = loadDemoData;
    }

    public void setDebugAuthToken(String debugAuthToken) {
        this.debugAuthToken = debugAuthToken;
    }

    public void setEnvironment(String environment) {
        LOGGER.error(String.format("Environment set: '%s'", environment));
        this.environment = environment;
    }

    public boolean getLoadDemoData() {
        return loadDemoData != null && loadDemoData.toLowerCase().trim().equals("true");
    }

    public boolean getDebugAuthToken() {
        return debugAuthToken != null && debugAuthToken.toLowerCase().trim().equals("true");
    }

    public String getVersion() {
        String version = "Unknown";
        try {
            version = this.getClass().getPackage().getImplementationVersion();
            LOGGER.debug(String.format("Identified version '%1'", version));
        } catch (Exception ignoreException) {
            LOGGER.error("An error has occurred while trying to retrieve the package version.");
        }
        return version;
    }

    public String getEnvironment() {
        if (environment == null || environment.isEmpty()) {
            return "Unknown";
        }
        return environment;
    }

}
