package app.demo.todo.controller;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Properties;

import org.springframework.boot.actuate.info.Info.Builder;
import org.springframework.boot.actuate.info.InfoContributor;
import org.springframework.stereotype.Component;

import app.demo.todo.utils.AppLogger;

// BOOT-INF/classes/git.properties should exist in the .jar file
// in some environments Actuator just does not pick it up
// No idea why, but this is a workaround
@Component
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
                ClassLoader classLoader = this.getClass().getClassLoader();
                InputStream input = classLoader.getResourceAsStream("git.properties");
                if (input == null) {
                    throw new RuntimeException("Unable to find git.properties");
                }

                LOGGER.debug("Found git.properties and reading it");
                try
                {
                    LOGGER.debug(readFromInputStream(input));
                }
                catch (Exception ex) {
                    LOGGER.error(String.format("Reading git.properties failed: '%s'", ex.getMessage()));
                }

                LOGGER.debug("Reopening git.properties");
                input = classLoader.getResourceAsStream("git.properties");
                if (input == null) {
                    throw new RuntimeException("Unable to reopen git.properties");
                }

                Properties prop = new Properties();
                prop.load(input);

                GitStatusInfoContributor.gitBuildTime = prop.getProperty("git.build.time");
                LOGGER.debug(
                        String.format("git.properties->git.build.time: '%s'", GitStatusInfoContributor.gitBuildTime));
                GitStatusInfoContributor.gitBuildVersion = prop.getProperty("git.build.version");
                LOGGER.debug(String.format("git.properties->git.build.version: '%s'",
                        GitStatusInfoContributor.gitBuildVersion));
                GitStatusInfoContributor.gitCommitIdAbbrev = prop.getProperty("git.commit.id.abbrev");
                LOGGER.debug(String.format("git.properties->git.commit.id.abbrev: '%s'",
                        GitStatusInfoContributor.gitCommitIdAbbrev));
                GitStatusInfoContributor.gitCommitIdFull = prop.getProperty("git.commit.id.full");
                LOGGER.debug(String.format("git.properties->git.commit.id.full: '%s'",
                        GitStatusInfoContributor.gitCommitIdFull));
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

    private String readFromInputStream(InputStream inputStream)
            throws IOException {
        StringBuilder resultStringBuilder = new StringBuilder();
        try (BufferedReader br = new BufferedReader(new InputStreamReader(inputStream))) {
            String line;
            while ((line = br.readLine()) != null) {
                resultStringBuilder.append(line).append("\n");
            }
            br.close();
        }
        return resultStringBuilder.toString();
    }
}


                // InputStream input =
                // this.getClass().getClassLoader().getResourceAsStream("/BOOT-INF/classes/git.properties");
                // if (input == null) {
                // input =
                // this.getClass().getClassLoader().getResourceAsStream("//BOOT-INF/classes/git.properties");
                // }
                // if (input == null) {
                // input =
                // this.getClass().getClassLoader().getResourceAsStream("/BOOT-INF/git.properties");
                // }
                // if (input == null) {
                // input =
                // this.getClass().getClassLoader().getResourceAsStream("//BOOT-INF/git.properties");
                // }
                // if (input == null) {
                // input =
                // this.getClass().getClassLoader().getResourceAsStream("git.properties");
                // }
                // if (input == null) {
                // input =
                // this.getClass().getClassLoader().getResourceAsStream("/**/git.properties");
                // }
                // if (input == null) {
                //     throw new RuntimeException("Unable to find git.properties");
                // }
                // LOGGER.debug("Found git.properties and reading it");
