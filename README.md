# rocker_extended

Utilities and extended definition files for Rstudio rocker containers.


## Rstudio in a singularity container

I find myself needing to use containerised versions of Rstudio pretty often.
Sometimes it's in places where i don't have root permission, so singularity is usually my only option (despite cgroups v2).

In `bin/rstudio_session.sh` is a script that will automatically set up an Rstudio server instance in a singularity container in the way [recommended by rocker](https://rocker-project.org/use/singularity.html).
To use it `bin/find_available_port.py` needs to be somewhere on your `PATH`, and you'll need to set two environment variables:

- `RSTUDIO_SINGULARITY_DEFAULT_IMAGE` Is the singularity SIF image file you want. 
- `RSTUDIO_SINGULARITY_DEFAULT_SESSIONDIR` Is a writable directory where you want to store server configurations etc necessary for Rstudio to work.


Alternatively, you can provide the `--sif` and `--session-dir` arguments at runtime.

> WARNING: the session directory will be deleted when you kill the server by default (disable with `--no-cleanup`).
> This folder is only for config files needed by Rstudio to run, it doesn't contain any information about your projects, history saved data etc.
> Don't store anything important in here, and there's no need to use an existing folder.
> I suggest you set a base directory with the environment variable in a hidden directory (e.g. `~/.rstudio_singularity_sessions`), or in a temporary directory.


This script is intended to be used with port-forwarding.
We don't have any of the remote-proxy stuff and SSL encryption that would be needed for public internet exposure.
The script will give you instructions of how to set up the SSH port forwarding when you run the script.

Note that we setup the login cookie to never expire, so once you've entered a password once it will always remember your browser, even if you restart the server.



## Dockerfiles

Because singularity files are more-or-less un-writable, it's difficult to install system libraries on the fly.
Things like libharfbuzz and libssl are common problems.

The containers in here just have a bunch of these C development libraries already installed so that you don't have to worry about it so much.
I'll update it as I encounter new things.
