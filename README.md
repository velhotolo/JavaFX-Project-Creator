# ☕ JavaFX (Maven) Project Generator

A small Bash script that scaffolds a ready-to-run **JavaFX + Maven** project in seconds. It asks a few questions, then generates the folder structure, a `pom.xml`, a minimal app with an FXML view and a controller, a dark-theme stylesheet and a `.gitignore`.

> 📚 This script was written as a Bash study project, so the source is heavily commented. Reading it top to bottom is a good way to see variables, user input, validation and heredocs working together.

---

## ✨ Features

- Interactive prompts with **sensible defaults** (press Enter to accept)
- Configurable **Group ID**, **Java version** and **JavaFX version**
- Input **validation** for the project name and the Java package name
- **Refuses to overwrite** an existing directory
- Generates a project that runs with a single command: `mvn javafx:run`

---

## 📋 Requirements

| Tool | Needed for | Notes |
|------|-----------|-------|
| Bash 4+ | Running the script | Linux, macOS (use `brew install bash` for an up-to-date version) or WSL/Git Bash on Windows |
| JDK 17+ | Compiling and running the generated project | JavaFX 21 requires Java 17 or newer |
| Maven 3.6+ | Building and running the generated project | `mvn -v` to check |
| A graphical desktop | Opening the JavaFX window | Won't work on a headless server |

The script itself only uses standard shell tools (`echo`, `read`, `mkdir`, `cat`, `tr`), so it needs nothing extra to *generate* a project. Java and Maven are needed only to *run* the result.

---

## 🚀 Installation

```bash
# 1. Save the script as create-javafx-project.sh, then make it executable
chmod +x create-javafx-project.sh

# 2. (Optional) Put it somewhere on your PATH to use it from anywhere
mkdir -p ~/bin
cp create-javafx-project.sh ~/bin/
```

---

## 🧭 Usage

```bash
./create-javafx-project.sh
```

The script asks four questions:

| Prompt | Default | Rules |
|--------|---------|-------|
| `Project name (directory/artifactId)` | *(required)* | Letters, digits, `.`, `_` and `-` only. The directory must not exist yet. |
| `Group ID` | `com.example` | Must be a valid Java package name (`com.mycompany.app`). No hyphens or spaces. |
| `Java version` | `21` | Used for the compiler `release` setting. |
| `JavaFX version` | `21.0.2` | Must exist on Maven Central. |

### Example session

```text
$ ./create-javafx-project.sh
=== JavaFX (Maven) Project Generator ===
Project name (directory/artifactId): monster-tracker
Group ID [com.example]: org.velhotolo
Java version [21]:
JavaFX version [21.0.2]:

Creating folder structure in ./monster-tracker...

✅ Project 'monster-tracker' created successfully!
To run the project:
  cd monster-tracker
  mvn javafx:run
```

### Run the generated project

```bash
cd monster-tracker
mvn javafx:run
```

A dark window opens with a label and a button. Clicking the button changes the label text.

---

## 📁 What gets generated

```text
monster-tracker/
├── .gitignore
├── pom.xml
└── src/main/
    ├── java/org/velhotolo/
    │   ├── App.java                # Application entry point
    │   └── MainController.java     # Handles the button click
    └── resources/org/velhotolo/
        ├── main-view.fxml          # Layout (label + button)
        └── style.css               # Dark theme
```

| File | Purpose |
|------|---------|
| `pom.xml` | Maven build file: Java version, JavaFX dependencies (`javafx-controls`, `javafx-fxml`) and the plugins that compile and run the app |
| `App.java` | Extends `Application`, loads the FXML, attaches the stylesheet and shows the window |
| `MainController.java` | Connected to the view via `fx:controller`; `@FXML` fields and methods are filled in by JavaFX |
| `main-view.fxml` | The interface described in XML (a `VBox` with a `Label` and a `Button`) |
| `style.css` | JavaFX CSS (properties start with `-fx-`) |
| `.gitignore` | Ignores `target/`, IDE folders and compiled classes |

> **Why do the resources live in a package folder?** `getClass().getResource("main-view.fxml")` looks for the file *relative to the class's package*. Putting the FXML and CSS in the same package path as `App.java` is what makes that lookup work.

---

## 🔍 How the script works

A walkthrough of the Bash concepts used, in the order they appear.

### 1. Shebang and `set -e`

```bash
#!/usr/bin/env bash
set -e
```

The first line tells the OS to run the file with Bash (found through `env`, which is more portable than hard-coding `/bin/bash`). `set -e` aborts the script when any command fails, so you never end up with a half-generated project.

### 2. Reading input with `read -rp`

```bash
read -rp "Group ID [com.example]: " GROUP_ID
```

`-p` shows the prompt on the same line, and `-r` stops backslashes from being treated as escape characters.

### 3. Default values with `${VAR:-default}`

```bash
GROUP_ID=${GROUP_ID:-com.example}
```

If `GROUP_ID` is empty or unset, use `com.example`. This is what lets the user just press Enter.

### 4. Validation with `[[ =~ ]]`

```bash
if [[ ! "$PROJECT_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: ..." >&2
  exit 1
fi
```

`[[ string =~ regex ]]` tests a string against a regular expression, and `!` negates it. Errors go to **stderr** (`>&2`) and the script exits with a non-zero status, which is the convention for "failed". The regex also rejects an empty name, which would otherwise build paths starting at `/`.

The Group ID regex is stored in a variable first (`GROUP_RE=...`) and used **unquoted**. Quoting the right side of `=~` would turn it into a literal string match.

### 5. Command substitution and `tr`

```bash
PACKAGE_DIR=$(echo "$GROUP_ID" | tr '.' '/')
```

`$(...)` captures a command's output. `tr '.' '/'` replaces every dot with a slash, turning `com.example` into `com/example`. (Pure-Bash alternative with no external command: `${GROUP_ID//./\/}`.)

### 6. `mkdir -p`

Creates every missing parent directory in one go and doesn't fail if the directory already exists.

### 7. Heredocs (`cat <<EOF`)

```bash
cat <<EOF >"$PROJECT_NAME/pom.xml"
<groupId>$GROUP_ID</groupId>
...
EOF
```

A *here document* feeds a block of text to `cat`, which `>` redirects into a file. Because the marker `EOF` is **unquoted**, the shell expands variables inside the block, so `$GROUP_ID` becomes the value you typed.

That has a side effect: any `$` that should appear literally in the output must be escaped. Maven's property syntax `${javafx.version}` is written as:

```bash
<version>\${javafx.version}</version>
```

Without the backslash, the shell would try to expand it and write an empty string into the `pom.xml`. (The opposite approach is a **quoted** marker, `<<'EOF'`, which disables all expansion.)

### 8. Quoting variables

Every path is written as `"$PROJECT_NAME/..."`. Double quotes prevent word splitting and globbing, which is a classic source of Bash bugs when values contain spaces.

---

## 🛠 Customization

| I want to... | Change this |
|--------------|-------------|
| Different default Java or JavaFX version | The `${JAVA_VERSION:-21}` and `${JAVAFX_VERSION:-21.0.2}` defaults |
| Different window size | `new Scene(root, 640, 480)` in the `App.java` heredoc |
| Light theme | The colors in the `style.css` heredoc |
| More generated files | Add another `cat <<EOF >"path"` block following the same pattern |
| Add a `module-info.java` | Create it in `$SRC_JAVA_DIR` with `requires javafx.controls; requires javafx.fxml;` and `opens $GROUP_ID to javafx.fxml;` |

---

## 🧯 Troubleshooting

| Problem | Likely cause and fix |
|---------|---------------------|
| `Permission denied` when running | Run `chmod +x create-javafx-project.sh` |
| `mvn: command not found` | Install Maven and check with `mvn -v` |
| `release version 21 not supported` | Your JDK is older than the version you chose. Check `java -version`, or pick a lower Java version |
| `Error: '<name>' already exists` | The script never overwrites. Pick another name or delete the old folder |
| Could not resolve `org.openjfx` artifacts | Check the JavaFX version exists on Maven Central and that you have internet access |
| Window doesn't open / `no display name and no $DISPLAY` | You're on a headless machine or SSH session. JavaFX needs a graphical desktop |
| `Location is not set` when starting | The FXML wasn't found. Make sure it sits in the same package path as `App.java` under `src/main/resources` |

---

## ⚠️ Known limitations

- The script does not check that Java or Maven are installed.
- It does not verify that the JavaFX version you type actually exists.
- Project names with uppercase letters are accepted, but Maven convention prefers lowercase with hyphens.
- The generated project runs on the classpath (no `module-info.java`), which is the simplest setup for learning.

---

## 🧠 Ideas for next steps (good Bash practice)

- Accept the answers as **command-line arguments** (`./create-javafx-project.sh my-app com.me 21`) using `$1`, `$2`, `$3` or `getopts`
- Add `-h/--help` and a **non-interactive** mode
- Check dependencies with `command -v mvn >/dev/null || { echo "Maven not found"; exit 1; }`
- Switch to `set -euo pipefail` for stricter error handling
- Offer to run `git init` and make a first commit at the end
- Split the file generation into functions (`generate_pom`, `generate_app`...)

---

## 📄 License

Free to use and modify for your own studies and projects.
