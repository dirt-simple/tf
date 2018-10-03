# Cloud Flare Single Script Worker

This example utilizes Cloudflare workers and routes to manage network requests at the edge.

## Usage Of The Single Worker Module

```
module "single_worker" {
    # ../ for local development (relative path),
    # for external usage reference github.com/dirt-simple/tf/cloudflare/single_worker
    source = "../"

    # The route patterns placed in this array will trigger the cloudflare worker
    enabled_route_patterns = ["blog.beeceej.com/*"]

    # The route patterns placed in this array will not trigger the cloudflare worker
    disabled_route_patterns = ["blog.beeceej.com/"]

    # This is your account zone. For non-enterprise accounts it will be your domain.
    account_zone = "beeceej.com"

    # script_path is the path to your script. This variable is optional. If left empty it will default to ./index.js
    script_path - "worker/index.js"
}

```