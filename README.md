# FastAPI "builder"

This repo is a relatively naive implementation of a "turn-key" approach for generating a FastAPI project repository.

## How to use

### Clone the repo

Simply clone / checkout this repo:

```bash
gh repo clone FNNDSC/fapp_build
cd fapp_build
```

### Decide on a project "name" and "description"

Next, decide on a some project "name" and a "description". The "name" should be a single word, preferably all lowercase, and ideally will denote the repository on github. The "description" is a short description of the project -- this should be quoted to protect the text from being interpreted by the shell.

### Now just run the `build.sh` script

Based on the "name" and "description", run the builder script:

```bash
./build.sh ~/src/pf_build pf_build "A FastAPI service that builds plugins"
```

where in general

```bash
./build.sh <repoBaseDir> <projectName> <projectDescription>
```

## Come on in!

Check the console for errors. Ideally there won't be any. Then head on over to the created direcory

```bash
cd ~/src/pf_build
```

and start coding!

## Yes, there are probably dragons

This "factory" is not very robust and was mostly created to scratch a recurring itch. I would usually copy an exist FastAPI app over to a new one, hacking away at it. This was not very efficient, and hence the idea to just have a script that creates most of skeleton, source files, docker file(s) and some documentation stubs for me.

Are there better ways to do this? Most certainly I'd imagine. You have been warned!

_-30-_
