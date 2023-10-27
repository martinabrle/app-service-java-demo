package app.demo.todo.controller;

import org.hibernate.tuple.BaselineAttributeInformation.Builder;
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

	@Autowired GitStatusInfoContributor gitStatusInfoContributor;

	@GetMapping("/info")
	public String getIndex(Model model) {
		LOGGER.debug("TODO GET called with action '/info'");
		
		gitStatusInfoContributor.contribute(null);
		model.addAttribute("version", appConfig.getVersion());
		model.addAttribute("environment", appConfig.getEnvironment());
		model.addAttribute("git.build.time", gitStatusInfoContributor.getGitBuildTime());
		model.addAttribute("git.build.version", gitStatusInfoContributor.getGitBuildVersion());
		model.addAttribute("git.commit.id.abbrev", gitStatusInfoContributor.getGitCommitIdAbbrev());
		model.addAttribute("git.commit.id.full", gitStatusInfoContributor.getGitCommitIdFull());

		return "info";
	}
}