

import static org.testng.AssertJUnit.assertTrue;

import java.io.File;
import java.lang.System;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.junit.runner.RunWith;

import com.intuit.karate.junit4.Karate;

import net.masterthought.cucumber.Configuration;
import net.masterthought.cucumber.ReportBuilder;

import org.apache.commons.io.FileUtils;

import org.testng.annotations.Test;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.AfterClass;

import com.intuit.karate.KarateOptions;
import com.intuit.karate.Results;
import com.intuit.karate.Runner;

@RunWith(Karate.class)
@KarateOptions(features = "classpath:CA")
public class TestRunner {
  private static Results finalResults;

  @BeforeClass
  public static void beforeClass() {
    System.setProperty("file.encoding","ISO-8859-1");
      // skip 'callSingle' in karate-config.js
  } 
 
  @AfterClass
  public static void afterClass() {
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
    System.setProperty("karate.options", "-t @Teardown");
    Runner.path("classpath:CA").parallel(envParallelThreads);

    generateReport(finalResults.getReportDir());
    assertTrue(finalResults.getErrorMessages(), finalResults.getFailCount() == 0);

    System.out.print(finalResults.getErrorMessages());
  }  
  

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
    System.out.println("THIS WENT INSIDE TESTPARALLEL");
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
    finalResults = Runner.path("classpath:CA").parallel(envParallelThreads);
  }

 
}
