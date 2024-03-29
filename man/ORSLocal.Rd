% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/local.R
\name{ORSLocal}
\alias{ORSLocal}
\title{ORS local instance}
\description{
Creates a new ORS instance object. This R6 class is typically
constructed by \code{\link{ors_instance}}.

For technical details on the setup of local ORS instances, refer to the
\href{https://giscience.github.io/openrouteservice/run-instance/}{official ORS reference}.
For details on how to use \code{ORSLocal} objects, refer to the installation
vignette:

\preformatted{
vignette("ors-installation", package = "rors")
}
}
\details{
\code{ORSLocal} defines methods for all four steps in the ORS setup:
\itemize{
\item{\bold{Extract: }}{Download an extract and set it up for graph building.}
\item{\bold{Compose: }}{Change docker settings that control how the service is set up.}
\item{\bold{Configuration: }}{Change the way ORS computes routes.}
\item{\bold{Docker: }}{Send commands to docker to control the ORS container.}
}
}
\section{Docker commands}{


Local ORS instances are built using Docker containers. Initializing
\code{ORSLocal} downloads a \code{docker-compose.yml} file that tells
Docker how to build an ORS container. The Docker backend is pulled as
a Docker image (see
\href{https://hub.docker.com/r/openrouteservice/openrouteservice}{Dockerhub}).
\code{rors} communicates with Docker from within R to setup and manage ORS
containers.

On Unix systems, Docker requires superuser permissions. In Unix shells,
this is not problematic. However, R cannot communicate with Docker without
explicitly being granted superuser permissions or at least permissions to
access Docker. Thus, \code{ORSLocal} checks if the current user is the
superuser or if the current user has access to the Docker group. If not,
it aborts. For more details on how to manage Docker as a non-root user on
Linux, refer to the
\href{https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user}{Docker documentation}.
Note that this procedure grants root-level privileges to a user and can
negatively impact your system's security.
}

\section{Jumpstarting}{


When first initializing \code{ORSLocal} or when first creating a new
directory, \code{ORSLocal} will ask you if you would like to perform a
jumpstart. Jumpstarting means creating an initial Docker build that runs
on default settings, config and an extract file from Heidelberg, Germany.
On the initial build, Docker also creates the file system of ORS instances
including a configuration file. Irrespective of your choice to jumpstart,
Docker only allows one routing profile and automatically uses the
default extract of Heidelberg on the initial run.

By jumpstarting, \code{ORSLocal} takes over this initial build,
so that subsequent builds run flawlessly without the need to manually
create the file system. This is deemed good practice by the ORS developer
team (refer to the
\href{https://giscience.github.io/openrouteservice/run-instance/installation/running-with-docker}{ORS reference}
for details).

Conversely, if you choose not to jumpstart (\code{dry = TRUE}),
\code{ORSLocal} does not interact with Docker until explicitly told to.
The configuration and extract files as well as the rest of the file system
do not exist yet. You can manually jumpstart by calling \code{$up()}.
Initializing a dry instance can be useful if you need to make changes to
the compose file before building ORS for the first time.
}

\section{Manual changes}{


\code{ORSLocal} provides a range of convenience methods to change the
setup of the ORS instance. All of these methods automatically read or write
their changes to disk. It is also possible to make direct changes to the
(parsed) configuration and compose files. In this case, reading and writing
also need to be done manually. To write changes to disk, run
\code{$update()}, e.g.:

\preformatted{
 ors$compose$parsed$services$`ors-app`$container_name <- "new-name-123"
 ors$update()
}

To read changes done manually to the files on disk, run
\code{$update("self")}.
}

\examples{
\dontrun{
# Download ORS, start docker and jumpstart a default session
ors <- ors_instance("~/ex_ors", version = "7.2.0")

# Take down the newly created instance
ors$down()

# Set a new extract file
ors$set_extract("Rutland")

# Allocate 100 MB of RAM
ors$set_ram(0.1)

# Add a routing profile
walking <- ors_profile("walking")
ors$add_profiles(walking)

# Set random port
ors$set_port()

# Change project name
ors$set_name("example-ors")

# Set up ORS
ors$up()

# Check if ORS container exists and is running
ors$is_built()
ors$is_running()

# Check if ORS is ready to use
ors$is_ready()

# Stop container, e.g. to make configuration changes
ors$stop()

# Make changes to the configuration
ors$set_endpoints(matrix = list(maximum_routes = 1e+05)) # default is 2500

# Change default profile settings
default <- ors_profile(maximum_snapping_radius = -1)
ors$add_profiles(default)

# If we make manual changes to the configuration, we need to apply the
# changes explicitly
ors$config$parsed$ors$engine$profiles$car$elevation <- FALSE
ors$update() # writes the current object state to the disk

# If the compose or config files are changed on disk, the object can be
# refreshed
ors$update("self") # reads the disk state to the R object

# Adding profiles does not work when the container is still built!
# Why? Because graphs need to be built for new profiles, so the container
# must be down.
if (FALSE) {
  bike <- ors_profile("bike-road")
  ors$add_profiles(bike) # only do this when the container is down!!
}

# Additionally, graphs are only re-built if we enable graph building.
# When changing the extract, this happens automatically, but we can also
# control graph building manually, e.g. for adding new profiles.
ors$set_graphbuilding(TRUE)

# Finally, start the container again to run the newly configured service
ors$start()
}


}
\section{Super class}{
\code{\link[rors:ORSInstance]{rors::ORSInstance}} -> \code{ORSLocal}
}
\section{Public fields}{
\if{html}{\out{<div class="r6-fields">}}
\describe{
\item{\code{paths}}{List of relevant file paths for the ORS setup. Includes
the top directory, compose file, config file and extract file.}

\item{\code{version}}{Version of the local ORS backend}

\item{\code{compose}}{Information of the compose file (\code{docker-compose.yml}).
The compose file holds various settings for the Docker setup. The most
important settings are included in this field:

\itemize{
\item{\code{ports}: A 2×2 matrix with Docker ports}
\item{\code{name}: Name of the Docker container}
\item{\code{memory}: List with memory information on total and free
system memory as well as initial and max memory allocated to the Docker
instance.}
\item{\code{image}: Version of the ORS image. \code{"latest"} refers
to the latest stable version. \code{"nightly"} refers to the devel
version.}
\item{\code{parsed}: Parsed compose file. When making changes to this
object, make sure to run \code{$update()} to apply the changes. For details,
refer to the \href{https://giscience.github.io/openrouteservice/run-instance/installation/running-with-docker#docker-configuration}{official reference}.}
}}

\item{\code{config}}{Information of the configuration file (\code{ors-config.yml}).
The config file holds various options about the ORS instance. This
field gives details about:

\itemize{
\item{profiles: A named vector of active routing profiles}
\item{parsed: Parsed configuration file. When making changes to
this obhect, make sure to run \code{$update()} to apply the changes.
For details, refer to the
\href{https://giscience.github.io/openrouteservice/run-instance/configuration/}{ORS reference}.}
}}

\item{\code{extract}}{Information on the extract file. Contains the name and
size of the selected extract file.}
}
\if{html}{\out{</div>}}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-ORSLocal-new}{\code{ORSLocal$new()}}
\item \href{#method-ORSLocal-update}{\code{ORSLocal$update()}}
\item \href{#method-ORSLocal-purge}{\code{ORSLocal$purge()}}
\item \href{#method-ORSLocal-report}{\code{ORSLocal$report()}}
\item \href{#method-ORSLocal-set_extract}{\code{ORSLocal$set_extract()}}
\item \href{#method-ORSLocal-rm_extract}{\code{ORSLocal$rm_extract()}}
\item \href{#method-ORSLocal-set_name}{\code{ORSLocal$set_name()}}
\item \href{#method-ORSLocal-set_port}{\code{ORSLocal$set_port()}}
\item \href{#method-ORSLocal-set_ram}{\code{ORSLocal$set_ram()}}
\item \href{#method-ORSLocal-set_graphbuilding}{\code{ORSLocal$set_graphbuilding()}}
\item \href{#method-ORSLocal-set_image}{\code{ORSLocal$set_image()}}
\item \href{#method-ORSLocal-add_profiles}{\code{ORSLocal$add_profiles()}}
\item \href{#method-ORSLocal-rm_profiles}{\code{ORSLocal$rm_profiles()}}
\item \href{#method-ORSLocal-set_endpoints}{\code{ORSLocal$set_endpoints()}}
\item \href{#method-ORSLocal-up}{\code{ORSLocal$up()}}
\item \href{#method-ORSLocal-down}{\code{ORSLocal$down()}}
\item \href{#method-ORSLocal-start}{\code{ORSLocal$start()}}
\item \href{#method-ORSLocal-stop}{\code{ORSLocal$stop()}}
\item \href{#method-ORSLocal-get_image}{\code{ORSLocal$get_image()}}
\item \href{#method-ORSLocal-get_container}{\code{ORSLocal$get_container()}}
\item \href{#method-ORSLocal-show_logs}{\code{ORSLocal$show_logs()}}
\item \href{#method-ORSLocal-is_built}{\code{ORSLocal$is_built()}}
\item \href{#method-ORSLocal-is_running}{\code{ORSLocal$is_running()}}
\item \href{#method-ORSLocal-is_init}{\code{ORSLocal$is_init()}}
\item \href{#method-ORSLocal-clone}{\code{ORSLocal$clone()}}
}
}
\if{html}{\out{
<details open><summary>Inherited methods</summary>
<ul>
<li><span class="pkg-link" data-pkg="rors" data-topic="ORSInstance" data-id="get_status"><a href='../../rors/html/ORSInstance.html#method-ORSInstance-get_status'><code>rors::ORSInstance$get_status()</code></a></span></li>
<li><span class="pkg-link" data-pkg="rors" data-topic="ORSInstance" data-id="is_mounted"><a href='../../rors/html/ORSInstance.html#method-ORSInstance-is_mounted'><code>rors::ORSInstance$is_mounted()</code></a></span></li>
<li><span class="pkg-link" data-pkg="rors" data-topic="ORSInstance" data-id="is_ready"><a href='../../rors/html/ORSInstance.html#method-ORSInstance-is_ready'><code>rors::ORSInstance$is_ready()</code></a></span></li>
</ul>
</details>
}}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-new"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-new}{}}}
\subsection{Method \code{new()}}{
Initialize the ORSInstance object.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$new(
  dir = ".",
  version = "7.2.0",
  overwrite = FALSE,
  dry = FALSE,
  verbose = TRUE,
  prompts = interactive()
)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{dir}}{\code{[character]}

Custom OpenRouteService directory. If not specified, the directory
will be downloaded to the system's home directory. If a directory called
\code{"openrouteservice-{version}"} is present, the download will be skipped.
Ignored if \code{server} is not \code{NULL}.}

\item{\code{version}}{\code{[character]}

The OpenRouteService version to use. Can either be a version number (e.g.
7.2.0) or \code{"master"}. Ignored if \code{server} is not \code{NULL}.}

\item{\code{overwrite}}{\code{[logical]}

Whether to overwrite the current OpenRouteService directory
if it exists.}

\item{\code{dry}}{\code{[logical]}

Whether to start a dry run, i.e. run an instance without jumpstarting.}

\item{\code{verbose}}{\code{[logical]}

Level of verbosity. If \code{TRUE}, shows informative warnings and messages,
spinners, progress bars and system notifications.}

\item{\code{prompts}}{\code{[logical]}

Whether to ask for permission throughout the setup. Defaults to
\code{TRUE} in interactive sessions.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-update"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-update}{}}}
\subsection{Method \code{update()}}{
Updates ORS instance. Use this to apply changes made either in the
file system or to the \code{\link{ors_instance}} object itself. This
method is automatically called when using any method of
\code{ors_instance} that changes the ORS setup.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$update(what = c("fs", "self"))}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{what}}{\code{[character]}

Whether to change the file system with changes in R or update the
instance object with changes in the file system. If \code{what = "self"},
parses the relevant files in the ORS directory and updates the
\code{ors_instance} object. If \code{what = "fs"}, updates the
compose file and config file based on the changes made to the
\code{ors_instance} object.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-purge"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-purge}{}}}
\subsection{Method \code{purge()}}{
Purge ORS instance, i.e. take down container, (optionally) delete
image, delete ORS directory, and clean up R6 class.

This method can be useful for testing and writing reproducible
examples and can easily be used together with \code{\link{on.exit}}.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$purge(image = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{image}}{\code{[logical]}

Whether to remove the docker image or keep it for other projects. The
default is \code{FALSE} to prevent accidentally breaking other projects.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-report"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-report}{}}}
\subsection{Method \code{report()}}{
Prints a situation report of the ORS instance. Invokes all relevant
print methods that summarize the current state of the instance
object.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$report()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-set_extract"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-set_extract}{}}}
\subsection{Method \code{set_extract()}}{
Download and set an OpenStreetMap extract for use in ORS. Wrapper for
\code{\link[osmextract:oe_get]{oe_get()}}.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$set_extract(
  place,
  provider = "geofabrik",
  timeout = NULL,
  file = NULL,
  do_use = TRUE,
  ...
)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{place}}{\code{[various]}

Place name, \code{sf/sfc/bbox} object or bounding box for which to
download an extract file. For details, refer to
\code{\link[osmextract:oe_match]{oe_match()}}.}

\item{\code{provider}}{\code{[character/NULL]}

Extract provider to download extract from. Available
providers can be found by running
\code{\link[osmextract:oe_providers]{oe_providers()}}. If \code{NULL},
tries all providers.}

\item{\code{timeout}}{\code{[numeric]}

Timeout for extract downloads. Defaults to \code{getOption("timeout")}.}

\item{\code{file}}{\code{[character/NULL]}

Path to a local OSM extract. Can either be a full path to any OSM file
or the filename of an OSM file in the data folder of ORS. If file is
specified, \code{place} and \code{provider} are ignored.}

\item{\code{do_use}}{\code{[logical]}

If \code{TRUE}, enables graph building with the new extract. If
\code{FALSE}, does not change the compose file at all.}

\item{\code{...}}{Further arguments passed to
\code{\link[osmextract:oe_get]{oe_get()}}.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-rm_extract"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-rm_extract}{}}}
\subsection{Method \code{rm_extract()}}{
Removes extract files from the data directory.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$rm_extract(...)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{...}}{File names of extract files in the data directory. All
files that exist are removed. Can also be a single vector of file
names.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-set_name"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-set_name}{}}}
\subsection{Method \code{set_name()}}{
Set a name for the ORS container.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$set_name(name = NULL)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{name}}{Name for the ORS container. If \code{NULL}, generates
a random name (\code{"ors-appXXXX"}).}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-set_port"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-set_port}{}}}
\subsection{Method \code{set_port()}}{
Set a port for the localhost of the ORS container.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$set_port(port = NULL)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{port}}{Port to use for the container. If \code{NULL}, assigns a
random port using
\code{\link[httpuv:randomPort]{randomPort()}}.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-set_ram"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-set_ram}{}}}
\subsection{Method \code{set_ram()}}{
Set initial and max memory that the ORS container is allowed to use.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$set_ram(init = NULL, max = NULL)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{init}}{\code{[numeric/NULL]}

Initial memory. This can change if more memory is needed. If not
specified, uses \code{max}. If both are \code{NULL}, estimates
memory.}

\item{\code{max}}{\code{[numeric/NULL]}

Maximum memory. The container is not allowed to use more
memory than this value. If not specified, uses \code{init}. If both are
\code{NULL}, estimates memory.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-set_graphbuilding"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-set_graphbuilding}{}}}
\subsection{Method \code{set_graphbuilding()}}{
Graph building specifies whether routing graphs should be (re-)built.
Turning graph building on enables new profiles to be built or the
extract to be changed but significantly increases setup time. Turn
this off if you are changing configuration options that do not alter
routing graphs.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$set_graphbuilding(mode)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{mode}}{\code{[logical]}

Whether to turn graph building on or off.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-set_image"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-set_image}{}}}
\subsection{Method \code{set_image()}}{
Set version of the ORS Docker image. This should preferably be compatible
with the compose version.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$set_image(version = NULL)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{version}}{\code{[character]}

Version specification of the ORS image.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-add_profiles"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-add_profiles}{}}}
\subsection{Method \code{add_profiles()}}{
Add routing profiles to the ORS configuration. ORS only builds routing
graphs for active profiles.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$add_profiles(...)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{...}}{Objects of class \code{\link{ors_profile}} or character
strings. If a character string is passed, it is interpreted as
\code{ors_profile(..., template = TRUE)}.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-rm_profiles"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-rm_profiles}{}}}
\subsection{Method \code{rm_profiles()}}{
Remove routing profiles from the ORS configuration.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$rm_profiles(...)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{...}}{Names of routing profiles to remove. \code{"default"}
removes profile defaults. Can also be a single character vector.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-set_endpoints"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-set_endpoints}{}}}
\subsection{Method \code{set_endpoints()}}{
Change endpoint-specific configurations. Specifies options that are
relevant for entire API endpoints such as isochrones.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$set_endpoints(...)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{...}}{\code{[list/NULL]}

Named arguments containing the configuration for the endpoints.
Available endpoits are \code{routing}, \code{isochrones},
\code{matrix}, and \code{snap}. Refer to
\href{https://github.com/GIScience/openrouteservice/blob/master/ors-api/src/main/resources/application.yml}{application.yml}
for a list of defaults.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-up"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-up}{}}}
\subsection{Method \code{up()}}{
Create the ORS docker container and setup the ORS backend on a local
host.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$up(wait = TRUE, ...)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{wait}}{\code{logical}

Whether to run a spinner and show a system notification when the setup
is completed. If \code{FALSE} releases the console after the Docker
container is created. You can then check the service status using
\code{$is_ready()}.}

\item{\code{...}}{Additional flags passed to the \code{docker up} command.}
}
\if{html}{\out{</div>}}
}
\subsection{Details}{
The exact command run by \code{$up()} is:

\code{docker compose -p [name] -f [compose file] up -d --no-build [...]}

The \code{-p} flag allows docker to run multiple ORS containers and keep
them separate. It uses the service name defined in the compose file.

If not found, \code{$up()} builds the underlying OpenRouteService docker
image specified by \code{version} during the initialization of
\code{ORSLocal}.

Usually in detach mode (\code{-d}), docker returns terminal control back
to the user. By default, \code{$up()} blocks the console, checks for
errors and notifies the user when the service setup has finished. This
behavior can be suppresed by setting \code{wait = FALSE}. The service
status can then be checked using \code{$is_ready()} or
\code{\link[=ors_ready]{ors_ready()}}. Container logs can be accessed by typing
\code{docker logs [name]} in the terminal.
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-down"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-down}{}}}
\subsection{Method \code{down()}}{
Stop and remove the ORS docker container. Use this if you want to make
changes to a running ORS setup such as changing the extract or selected
profiles.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$down()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-start"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-start}{}}}
\subsection{Method \code{start()}}{
Start the ORS docker container.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$start(wait = TRUE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{wait}}{\code{logical}

Whether to run a spinner and show a system notification when the setup
is completed. If \code{FALSE} releases the console after the Docker
container is created. You can then check the service status using
\code{$is_ready()}.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-stop"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-stop}{}}}
\subsection{Method \code{stop()}}{
Stop the ORS docker container.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$stop()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-get_image"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-get_image}{}}}
\subsection{Method \code{get_image()}}{
Retrieve technical information on the docker image used.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$get_image()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-get_container"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-get_container}{}}}
\subsection{Method \code{get_container()}}{
Retrieve technical information on the docker container used.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$get_container()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-show_logs"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-show_logs}{}}}
\subsection{Method \code{show_logs()}}{
Show container logs as returned by \code{docker logs}. Useful for
debugging docker setups.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$show_logs(format = TRUE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{format}}{\code{[logical]}

If \code{TRUE}, includes ANSI colors and adds exdents. Otherwise,
trims ANSI colors. Disabling formatting increases performance, which
can be useful for larger logs.}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-is_built"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-is_built}{}}}
\subsection{Method \code{is_built()}}{
Checks if the ORS container is built. You can control this state
using \code{$up()} and \code{$down()}.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$is_built()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-is_running"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-is_running}{}}}
\subsection{Method \code{is_running()}}{
Checks if the ORS container is running. You can control this state
using \code{$start()} and \code{$stop()}. Check \code{$is_ready()} to see
if the ORS setup succeeded.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$is_running()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-is_init"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-is_init}{}}}
\subsection{Method \code{is_init()}}{
Checks if ORS is initialized. ORS is initialized if it was built
for the first time. An initialized ORS instance has a subdirectory
called \code{"graphs"} that contains built graphs for at least one
routing profile. \code{$is_init()} therefore checks for the
existence of at least one sub-directory of \code{"graphs"}.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$is_init()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-ORSLocal-clone"></a>}}
\if{latex}{\out{\hypertarget{method-ORSLocal-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ORSLocal$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
