# Gemini Enterprise a.k.a Agentspace custom domain

This repo implements the steps from [this Colab document](https://codelabs.developers.google.com/agentspace-networking-customdomain#6) to implement a custom domain for Gemini Enterprise.

The current implementation acts somewhat like a redirect, hence the user will eventually see the `vertexaisearch` url :(. I think this is to support things like browser cookies that must respect the final domain, will investigate more.

## Installation

Set the variables in `terraform.tfvars`

Then install:

  $ tf init && tf apply --auto-approve

