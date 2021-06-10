package CA;

import static org.testng.AssertJUnit.assertTrue;

import java.io.File;
// import java.lang.System;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;


import net.masterthought.cucumber.Configuration;
import net.masterthought.cucumber.ReportBuilder;

import org.apache.commons.io.FileUtils;
import org.testng.annotations.Test;

import com.intuit.karate.KarateOptions;
import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import com.intuit.karate.core.ExecutionHook;
import com.intuit.karate.core.Scenario;
import com.intuit.karate.core.ScenarioContext;
import com.intuit.karate.core.ScenarioResult;
import com.intuit.karate.core.Feature;
import com.intuit.karate.core.FeatureResult;
import com.intuit.karate.core.ExecutionContext;
import com.intuit.karate.core.Step;
import com.intuit.karate.core.StepResult;
import com.intuit.karate.http.HttpRequestBuilder;
import com.intuit.karate.core.PerfEvent;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.StringWriter;
import java.io.FileWriter;
import java.io.FileReader;
import java.io.IOException;

@KarateOptions()
public class TestRunner {

  private static void generateReport(String karateOutputPath) {
    Collection<File> jsonFiles =
        FileUtils.listFiles(new File(karateOutputPath), new String[] {"json"}, true);
    List<String> jsonPaths = new ArrayList(jsonFiles.size());
    jsonFiles.forEach(file -> jsonPaths.add(file.getAbsolutePath()));
    Configuration config = new Configuration(new File("target"), "CA API Test Automation");
    ReportBuilder reportBuilder = new ReportBuilder(jsonPaths, config);
    reportBuilder.generateReports();
  }

  @Test
  public void testParallel() {
    //Read environment variable "parallelThreads"
    //Defaults to 4 parallel threads if not set
    int envParallelThreads = 0;
    try {
      envParallelThreads =  Integer.parseInt(
                              System.getenv("parallelThreads")
                            );
    } catch (NumberFormatException e) {
      envParallelThreads = 4;
    }

    System.out.println("Parallel Threads: " + envParallelThreads);

    // Results results = Runner.path("classpath:CA").hook(new ExecHook()).parallel(envParallelThreads);
    Results results = Runner.path("classpath:CA").parallel(envParallelThreads);
    generateReport(results.getReportDir());
    assertTrue(results.getErrorMessages(), results.getFailCount() == 0);
  }
}
