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
> 5. Update the `automata/*` CI executions instructions matching the project.
> 6. Delete this blockquote once everything is completed.




## Why It Matters
State the business reasons for this project.

1. **Working things out efficiently with pinpoint accuracy** - template
   standardizes all marketing and presentable elements so just focus on the
   project development.
2. **Steadily for continuous improvement** - version controlled and improve
   iteratively.
3. **Simple and scalable** - just one git and some changes; you get a decent
   repo ready to deploy.




## Development
This section covers the necessary information for the project's developers and
maintainers.



### Directory Structure
```
automata/			🠚 house the projects' CI automation scripts.
automata/services		🠚 house tested and pre-built CI automation functions.
bin/				🠚 default build output directory.
pkg/				🠚 default package output directory.
resources/			🠚 housing all indirect raw materials and assets.
src/				🠚 house actual source codes (base directory).
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




### Native Continuous Integration (Native CI) Infrastructure
This repository is governed by a native CI scripted using
[Polygot Script](https://github.com/ChewKeanHo/PolygotScript) called `ci.cmd`.
If you are new and wanted to contribute, you may start off by following the
breadcrumbs via commands starting from `automata/` directory where the
developers housed their automated continuous development commands. As for
operating the repository, among the commands available are:


#### `SETUP` - Setup the Tooling in Your Local Environment
This is for setting up the necessary tooling (e.g. programming language's
engine) and etc in your local environment. The command:

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
