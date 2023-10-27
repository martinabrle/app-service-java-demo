package app.demo.todo.controller;

import java.io.InputStream;
import java.util.Properties;

import org.springframework.boot.actuate.info.Info.Builder;
import org.springframework.boot.actuate.info.InfoContributor;

import app.demo.todo.utils.AppLogger;

// BOOT-INF/classes/git.properties should exist in the .jar file
// in some environments Actuator just does not pick it up
// No idea why, but this is a workaround
public class GitStatusInfoContributor implements InfoContributor {
    private static boolean gitInfoLoaded = false;
    private static String gitBuildTime = null;
    private static String gitBuildVersion = null;
    private static String gitCommitIdAbbrev = null;
    private static String gitCommitIdFull = null;

    public static final AppLogger LOGGER = new AppLogger(GitStatusInfoContributor.class);

    public String getGitBuildTime() {
        loadProperties();
        return gitBuildTime;
    }
    public String getGitBuildVersion() {
        loadProperties();
        return gitBuildVersion;
    }

    public String getGitCommitIdAbbrev() {
        loadProperties();
        return gitCommitIdAbbrev;
    }
    public String getGitCommitIdFull() {
        loadProperties();
        return gitCommitIdFull;
    }

    private void loadProperties() {
        if (!GitStatusInfoContributor.gitInfoLoaded) {
            try {
                InputStream input = this.getClass().getClassLoader().getResourceAsStream("/BOOT-INF/classes/git.properties");
                if (input == null) {
                    input = this.getClass().getClassLoader().getResourceAsStream("//BOOT-INF/classes/git.properties");
                }
                if (input == null) {
                    input = this.getClass().getClassLoader().getResourceAsStream("/BOOT-INF/git.properties");
                }
                if (input == null) {
                    input = this.getClass().getClassLoader().getResourceAsStream("//BOOT-INF/git.properties");
                }
                if (input == null) {
                    input = this.getClass().getClassLoader().getResourceAsStream("git.properties");
                }
                if (input == null) {
                    input = this.getClass().getClassLoader().getResourceAsStream("/**/git.properties");
                }
                if (input == null) {
                    throw new RuntimeException("Unable to find git.properties");
                }
                LOGGER.debug("Found git.properties and reading it");

                Properties prop = new Properties();

                prop.load(input);

                GitStatusInfoContributor.gitBuildTime = prop.getProperty("git.build.time");
                GitStatusInfoContributor.gitBuildVersion = prop.getProperty("git.build.version");
                GitStatusInfoContributor.gitCommitIdAbbrev = prop.getProperty("git.commit.id.abbrev");
                GitStatusInfoContributor.gitCommitIdFull = prop.getProperty("git.commit.id.full");
                GitStatusInfoContributor.gitInfoLoaded = true;
            } catch (Exception ex) {
                LOGGER.error(String.format("Git Info contributor call failed: '%s'", ex.getMessage()));
                GitStatusInfoContributor.gitBuildTime = "unknown";
                GitStatusInfoContributor.gitBuildVersion = "unknown";
                GitStatusInfoContributor.gitCommitIdAbbrev = "unknown";
                GitStatusInfoContributor.gitCommitIdFull = "unknown";
                GitStatusInfoContributor.gitInfoLoaded = true;
            }
        }
    }

    @Override
    public void contribute(Builder builder) {
        LOGGER.debug("Git Info contributor called");

        builder.withDetail("git.build.time", getGitBuildTime());
        builder.withDetail("git.build.version", gitBuildVersion);
        builder.withDetail("git.commit.id.abbrev", getGitCommitIdAbbrev());
        builder.withDetail("git.commit.id.full", getGitCommitIdFull());

        LOGGER.debug("Git Info contributor called returned OK");
    }
}
