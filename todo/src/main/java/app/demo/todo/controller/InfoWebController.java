package app.demo.todo.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import app.demo.todo.AppConfig;
import app.demo.todo.utils.AppLogger;

@Controller
public class InfoWebController {

	public static final AppLogger LOGGER = new AppLogger(InfoWebController.class);
	
	@Autowired
    private AppConfig appConfig;

	GitStatusInfoContributor gitStatusInfoContributor = new GitStatusInfoContributor();

	@GetMapping("/info")
	public String getIndex(Model model) {
		LOGGER.debug("TODO GET called with action '/info'");
		
		String version = appConfig.getVersion();
		if (version == null || version.isEmpty()) {
			LOGGER.info("Package version returned as empty. Trying to get the version from git.");
			version = gitStatusInfoContributor.getGitBuildVersion();
		}
		model.addAttribute("version", version);
		model.addAttribute("environment", appConfig.getEnvironment());
		model.addAttribute("git_build_time", gitStatusInfoContributor.getGitBuildTime());
		model.addAttribute("git_build_version", gitStatusInfoContributor.getGitBuildVersion());
		model.addAttribute("git_commit_id_abbrev", gitStatusInfoContributor.getGitCommitIdAbbrev());
		model.addAttribute("git_commit_id_full", gitStatusInfoContributor.getGitCommitIdFull());

		return "info";
	}
}