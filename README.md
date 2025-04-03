# rocker_extended

Utilities and extended definition files for Rstudio rocker containers.

> Note: It seems that [apptainer](https://apptainer.org/docs/user/main/index.html), is the new open source version of singularity.
> Sylabs went corporate or something. Most of the commands are the same.
> For backwards compatibility Environment variables containing the word `APPTAINER` will also work if you type `SINGULARITY`.


## Rstudio in a singularity container

I find myself needing to use containerised versions of Rstudio pretty often.
Sometimes it's in places where i don't have root permission, so singularity is usually my only option (despite cgroups v2).

In `bin/rstudio_session.sh` is a script that will automatically set up an Rstudio server instance in a singularity/apptainer container in the way [recommended by rocker](https://rocker-project.org/use/singularity.html).
To use it `bin/find_available_port.py` needs to be somewhere on your `PATH`, and you'll need to set two environment variables:

- `RSTUDIO_APPTAINER_DEFAULT_IMAGE` Is the singularity SIF image file you want. 
- `RSTUDIO_APPTAINER_DEFAULT_SESSIONDIR` Is a writable directory where you want to store server configurations etc necessary for Rstudio to work.


Alternatively, you can provide the `--sif` and `--session-dir` arguments at runtime.

> WARNING: the session directory will be deleted when you kill the server by default (disable with `--no-cleanup`).
> This folder is only for config files needed by Rstudio to run, it doesn't contain any information about your projects, history saved data etc.
> Don't store anything important in here, and there's no need to use an existing folder.
> I suggest you set a base directory with the environment variable in a hidden directory (e.g. `~/.rstudio_apptainer_sessions`), or in a temporary directory.


This script is intended to be used with port-forwarding.
We don't have any of the remote-proxy stuff and SSL encryption that would be needed for public internet exposure.
The script will give you instructions of how to set up the SSH port forwarding when you run the script.

Note that we setup the login cookie to never expire, so once you've entered a password once it will always remember your browser, even if you restart the server.
For some reason it does actually expire after a couple of months, but it's easy enough just to re-authenticate in that case.


## `Dockerfile`

To build the container image, the easiest thing is to build with docker and then convert to a apptainer/singularity image.
From this directory run:

```
sudo docker build -t rocker_extended:4.4.3 .
sudo apptainer build ./rocker_extended-4.4.3.sif docker-daemon://rocker_extended:4.4.3
```

Then copy your `.sif` image file wherever you need it.

Change the version numbers as new rocker versions become available on dockerhub (https://hub.docker.com/r/rocker/tidyverse/tags).

Because singularity/apptainer images are more-or-less un-writable (unless you work as a sandbox), it's difficult to install system libraries on the fly.
Things like libcurl, libxml2, libharfbuzz and libssl are common problems.

This container just has a bunch of these C development libraries already installed so that you don't have to worry about it so much.
I'll update it as I encounter new things.

I suggest using [Renv](https://rstudio.github.io/renv/index.html) to install your actual project packages.


## Run a server

Assuming the files in the `bin` folder here are somewhere on your path, you can start an Rstudio server like so.


```bash
rstudio_session.sh --port 8789
```

If the environment variables `RSTUDIO_APPTAINER_DEFAULT_IMAGE` or `RSTUDIO_APPTAINER_DEFAULT_SESSIONDIR` are not set, you can manually set these using the `--sif` and `--session-dir` parameters, respectively.

If no port is specified, it will try to find a random port number that isn't currently in use.
I recommend manually setting a port close to 8787 but not exactly 8787.
Hopefully that will be slightly less concerning to your poor sys admins.
