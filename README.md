# Template Repository
[![Holloway's Template](resources/logos/logo-1200x630.svg)](https://github.com/hollowaykeanho/Template)

This repo serves as a template for all (Holloway) Chew, Kean Ho's new project
repository. It setups and includes all necessary and easy-to-modify artworks,
`README.md`, `LICENSE`, and `.gitignore` files that are crucial for a git
repository.

> [!IMPORTANT]
> **WHAT TO UPDATE AFTER CLONING**:
>
> 1. Update the `resources/logos/principle-canvas` logo files and re-generate
>    all the output logos OR delete them entirely.
> 2. Update this `README.md` especially dealing with title + anything below for
>    marking and business objectives (like WHY then HOW).
> 3. Select A `LICENSE.pdf` file with the appropriate license(s).
> 4. Add a `CODE_OF_CONDUCT.md` file with the appropriate legal clauses(s).
> 5. Update the `CONFIG.toml` matching the project metadata.
> 6. Select one of the placeholding technologies (e.g. `srcGO` or `srcPYTHON`)
>    and rename it to `src` directory.
> 7. Update your `src/.ci` automation job recipes if needed.
> 8. Delete this blockquote once everything is completed.




## Why It Matters
State the business reasons for this project.

1. **Working things out extremely efficiently with pinpoint accuracy** - get
   all the ecosystem deployments up and ready, out of the way and just focus on
   product development.
2. **Steadily for continuous improvement** - version controlled and improve
   iteratively.
3. **Simple and scalable** - just one git and some changes; you get a decent
   repo ready to deploy.




## Development
This section covers the necessary information for the project's developers and
maintainers.



### Directory Structure
```
automataCI/			🠚 house the projects' CI automation scripts.
automataCI/services		🠚 house tested and pre-built CI automation functions.
bin/				🠚 default build output directory.
pkg/				🠚 default package output directory.
resources/			🠚 housing all indirect raw materials and assets.
src/				🠚 house actual source codes (base directory).
src/.ci/			🠚 house source codes technology-specific CI automation jobs.
tools/				🠚 default tooling (e.g. prog. language bin/).
tmp/				🠚 default temporary workspace.
CONFIG.toml			🠚 configure project's settings data for CI.
ci.cmd				🠚 CI start point (no modification required).
VERSION				🠚 generated file from CI stating the project version.
LICENSE[_type]{.md,.pdf}	🠚 repository's meta-level license file.
README.md			🠚 repository's readme file.
SECURITY.md			🠚 repository's security instruction file.
```



### Branch Management
The default uses the following branch managements:

```
main				= for customers who use git (house stable releases)
next || staging || testing	= [OPTIONAL] for test developers to test the next release
edge || experimental		= for project maintainer to develop new feature.
```



### Native Continuous Integration (AutomataCI) Infrastructure
This repository is governed by an automation CI scripted using
[Polygot Script](https://github.com/ChewKeanHo/PolygotScript) called `ci.cmd`.
The technology behind is `AutomataCI` built specifically to operate using only
the native OS functionalities (`POSIX Shell` for UNIX OSes and `PowerShell`
for Windows OS).

Generally, you **DO NOT** need to mess with the CI's core system housed in
`automataCI/` directory. Your CI job recipes are housed in `src/.ci/` directory
and AutomataCI will auto-detect and engage them immediately.

However, if you are new and wanted to contribute, you may start off by following
the breadcrumbs or tracing via commands starting from your job recipe. The only
2 knowledge set required are:

1. POSIX complaint shell scripting (not BASH)
2. Windows' native PowerShell

Otherwise, you should only use the following CI commands and work on your
business inside `src/` directory


#### `SETUP` - Setup the Tooling in Your Local Environment
This is for setting up the necessary tooling (e.g. programming language's
engine) and etc in your local environment. If you already setup before, you
may not need this step. The command:

```
# UNIX (MacOS, GNU, Linux)
$ . ci.cmd setup

# WINDOWS
$ ./ci.cmd setup
```


#### `START` - To Start Your Development Environment
This is to start your current terminal session for the repository development.
It parses and facilitates all the pathing and setup the necessary files for the
project development needs (e.g. language binary, etc):

> [!IMPORTANT]
>
> For Windows OS, due to Batch & PowerShell technological limitations, you may
> or may not be able to engage properly. Hence, please read the on-screen
> instructions just in case.

```
# UNIX (MacOS, GNU, Linux)
$ . ci.cmd start

# WINDOWS
$ ./ci.cmd start
```


#### `TEST` - To Run the Test Automation
This is to run the current project's test automations.

```
# UNIX (MacOS, GNU, Linux)
$ . ci.cmd test

# WINDOWS
$ ./ci.cmd test
```


#### `PREPARE` - To Update The Project Dependencies
This is to run the project's dependencies' fetching and prepare the project.
Its update abilities may or may not share the same ability with `START` solely
under the maintainers' discretion.

```
# UNIX (MacOS, GNU, Linux)
$ . ci.cmd prepare

# WINDOWS
$ ./ci.cmd prepare
```


#### `BUILD` - To Build The Project Output
This is to run the project's build sequences and generate the instructed
outputs.

```
# UNIX (MacOS, GNU, Linux)
$ . ci.cmd build

# WINDOWS
$ ./ci.cmd build
```


#### `PACKAGE` - To Package the Project Output
This is to run the project's supported packaging sequences for various
distribution channels.

```
# UNIX (MacOS, GNU, Linux)
$ . ci.cmd package

# WINDOWS
$ ./ci.cmd package
```


#### `RELEASE` - To Release the Project Packages
This is to run the project's upstream sequences for releasing the packages to
the various distribution channels.

```
# UNIX (MacOS, GNU, Linux)
$ . ci.cmd release

# WINDOWS
$ ./ci.cmd release
```


#### `COMPOSE` - To Generate the Documentation Artifacts
This is to run the project's documentations automation.

```
# UNIX (MacOS, GNU, Linux)
$ . ci.cmd compose

# WINDOWS
$ ./ci.cmd compose
```


#### `PUBLISH` - To Publish the Documentations
This is to run the project's documents publishing sequences.

```
# UNIX (MacOS, GNU, Linux)
$ . ci.cmd publish

# WINDOWS
$ ./ci.cmd publish
```




### GitHub Actions
By default, the GitHub action only executes in this sequence:

1. `setup`
2. `start`
3. `prepare`
4. `test`
5. `build`
6. `compose`

for `git push` against `main`, `next`, `staging`, or `testing` branches.

For `package`, `release`, and `publish` CI jobs, due to the invovlement of
private identitiy signing keys, they are best to be implemented at the local
side (to protect the key from any unnecessary leak due to 3rd-party).




## License
This project is licensed under multiple licenses such that:

1. Main license - [??? License](LICENSE)
2. CI Automation license - [Apache 2.0](automata/LICENSE)
