package com.mdjunayet.studyleveling;

import java.io.File;
import java.io.IOException;

public class App {
    public static void main(String[] args) {
        try {
            File projectRoot = findProjectRoot();
            String mavenCommand = findMavenCommand();

            ProcessBuilder processBuilder = new ProcessBuilder(
                    mavenCommand,
                    "-q",
                    "-DskipTests",
                    "compile",
                    "exec:java",
                    "-Dexec.mainClass=com.mdjunayet.studyleveling.AppMain"
            );
            processBuilder.directory(projectRoot);
            processBuilder.inheritIO();

            Process process = processBuilder.start();
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                System.exit(exitCode);
            }
        } catch (IOException e) {
            System.err.println("Unable to launch Study Leveling: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            System.err.println("Launch interrupted: " + e.getMessage());
            System.exit(1);
        }
    }

    private static File findProjectRoot() throws IOException {
        File currentDirectory = new File(System.getProperty("user.dir")).getCanonicalFile();

        while (currentDirectory != null && !new File(currentDirectory, "pom.xml").isFile()) {
            currentDirectory = currentDirectory.getParentFile();
        }

        if (currentDirectory == null) {
            throw new IOException("Could not locate the project root");
        }

        return currentDirectory;
    }

    private static String findMavenCommand() {
        File bundledMaven = new File("/tmp/apache-maven-3.9.9/bin/mvn");
        if (bundledMaven.isFile() && bundledMaven.canExecute()) {
            return bundledMaven.getAbsolutePath();
        }

        return "mvn";
    }
}
