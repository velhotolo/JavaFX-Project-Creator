#!/usr/bin/env bash
# ============================================================
# JavaFX (Maven) Project Generator
#
# Asks a few questions and creates a ready-to-run JavaFX project:
# pom.xml, an App class, a controller, an FXML view, a CSS file
# and a .gitignore.
#
# Usage: ./create-javafx-project.sh
# ============================================================

# Stop the script as soon as any command fails, instead of
# silently continuing and creating a half-broken project
set -e

echo "=== JavaFX (Maven) Project Generator ==="

# read -r : do not treat backslashes as escape characters
# read -p : show a prompt on the same line
read -rp "Project name (directory/artifactId): " PROJECT_NAME

# [[ ... =~ regex ]] tests a string against a regular expression.
# Only letters, digits, dots, underscores and hyphens are allowed, which also
# rejects an empty name (an empty name would build paths starting at "/").
if [[ ! "$PROJECT_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: the project name may only contain letters, digits, '.', '_' or '-'." >&2
  exit 1
fi

# -e is true if the path exists (file or directory).
# Never overwrite someone's existing work.
if [[ -e "$PROJECT_NAME" ]]; then
  echo "Error: '$PROJECT_NAME' already exists. Choose another name or remove it first." >&2
  exit 1
fi

# ${VAR:-default} uses "default" when VAR is empty or unset,
# so pressing Enter accepts the value shown in brackets
read -rp "Group ID [com.example]: " GROUP_ID
GROUP_ID=${GROUP_ID:-com.example}

# The group ID is also used as the Java package, so it must be a valid one
GROUP_RE='^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$'
if [[ ! "$GROUP_ID" =~ $GROUP_RE ]]; then
  echo "Error: '$GROUP_ID' is not a valid Java package name (example: com.example)." >&2
  exit 1
fi

read -rp "Java version [21]: " JAVA_VERSION
JAVA_VERSION=${JAVA_VERSION:-21}

read -rp "JavaFX version [21.0.2]: " JAVAFX_VERSION
JAVAFX_VERSION=${JAVAFX_VERSION:-21.0.2}

# Command substitution $(...) captures a command's output into a variable.
# tr swaps each dot for a slash (e.g. com.example -> com/example),
# because Java packages map to directories
PACKAGE_DIR=$(echo "$GROUP_ID" | tr '.' '/')

SRC_JAVA_DIR="$PROJECT_NAME/src/main/java/$PACKAGE_DIR"
SRC_RES_DIR="$PROJECT_NAME/src/main/resources/$PACKAGE_DIR"

echo ""
echo "Creating folder structure in ./$PROJECT_NAME..."
# mkdir -p creates every missing parent folder and doesn't complain if it exists
mkdir -p "$SRC_JAVA_DIR"
mkdir -p "$SRC_RES_DIR"

# ------------------------------------------------------------
# About the heredocs below (cat <<EOF ... EOF):
# everything between the markers is written to the file after the
# shell expands variables like $GROUP_ID. When a literal "$" must reach
# the file (Maven's ${javafx.version}), it is escaped with a backslash.
# ------------------------------------------------------------

# 1. pom.xml
cat <<EOF >"$PROJECT_NAME/pom.xml"
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>$GROUP_ID</groupId>
    <artifactId>$PROJECT_NAME</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.source>$JAVA_VERSION</maven.compiler.source>
        <maven.compiler.target>$JAVA_VERSION</maven.compiler.target>
        <javafx.version>$JAVAFX_VERSION</javafx.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.openjfx</groupId>
            <artifactId>javafx-controls</artifactId>
            <version>\${javafx.version}</version>
        </dependency>
        <dependency>
            <groupId>org.openjfx</groupId>
            <artifactId>javafx-fxml</artifactId>
            <version>\${javafx.version}</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.13.0</version>
                <configuration>
                    <release>$JAVA_VERSION</release>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.openjfx</groupId>
                <artifactId>javafx-maven-plugin</artifactId>
                <version>0.0.8</version>
                <executions>
                    <execution>
                        <id>default-cli</id>
                        <configuration>
                            <mainClass>$GROUP_ID.App</mainClass>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# 2. Main application class (App.java)
cat <<EOF >"$SRC_JAVA_DIR/App.java"
package $GROUP_ID;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

import java.io.IOException;

public class App extends Application {

    @Override
    public void start(Stage stage) throws IOException {
        FXMLLoader loader = new FXMLLoader(getClass().getResource("main-view.fxml"));
        Parent root = loader.load();
        
        Scene scene = new Scene(root, 640, 480);
        scene.getStylesheets().add(getClass().getResource("style.css").toExternalForm());

        stage.setTitle("$PROJECT_NAME");
        stage.setScene(scene);
        stage.show();
    }

    public static void main(String[] args) {
        launch();
    }
}
EOF

# 3. Controller (MainController.java)
cat <<EOF >"$SRC_JAVA_DIR/MainController.java"
package $GROUP_ID;

import javafx.fxml.FXML;
import javafx.scene.control.Label;

public class MainController {

    @FXML
    private Label welcomeText;

    @FXML
    protected void onHelloButtonClick() {
        welcomeText.setText("JavaFX is running perfectly!");
    }
}
EOF

# 4. View (main-view.fxml)
cat <<EOF >"$SRC_RES_DIR/main-view.fxml"
<?xml version="1.0" encoding="UTF-8"?>

<?import javafx.geometry.Insets?>
<?import javafx.scene.control.Button?>
<?import javafx.scene.control.Label?>
<?import javafx.scene.layout.VBox?>

<VBox alignment="CENTER" spacing="20.0" xmlns:fx="http://javafx.com/fxml"
      fx:controller="$GROUP_ID.MainController">
    <padding>
        <Insets bottom="20.0" left="20.0" right="20.0" top="20.0"/>
    </padding>

    <Label fx:id="welcomeText" text="Welcome to JavaFX"/>
    <Button text="Click here" onAction="#onHelloButtonClick"/>
</VBox>
EOF

# 5. Styles (style.css)
cat <<EOF >"$SRC_RES_DIR/style.css"
.root {
    -fx-font-family: sans-serif;
    -fx-background-color: #2b2b2b;
}

.label {
    -fx-font-size: 16px;
    -fx-text-fill: #f0f0f0;
}

.button {
    -fx-background-color: #3c3f41;
    -fx-text-fill: #ffffff;
    -fx-border-color: #555555;
    -fx-border-radius: 4px;
    -fx-padding: 8px 16px;
}

.button:hover {
    -fx-background-color: #4c5052;
}
EOF

# 6. Default .gitignore
cat <<EOF >"$PROJECT_NAME/.gitignore"
target/
*.class
.project
.classpath
.settings/
.idea/
*.iml
.vscode/
EOF

echo ""
echo "✅ Project '$PROJECT_NAME' created successfully!"
echo "To run the project:"
echo "  cd $PROJECT_NAME"
echo "  mvn javafx:run"
