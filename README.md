# Gemini Enterprise a.k.a Agentspace custom domain

This repo implements the steps from [this Colab document](https://codelabs.developers.google.com/agentspace-networking-customdomain#6) to implement a custom domain for Gemini Enterprise.

The current implementation acts somewhat like a redirect, hence the user will eventually see the `vertexaisearch` url :(.

The reason is that when the user logs on the first time, the user is redirect to the accounts login page, with a redirect_uri that points back to the vertexaisearch app. We're unable to change this with this 'hack', because we're unable to change the redirect uri for the users first time login. Trying to workaround this issue is .... unadvisable!

## Installation

Set the variables in `terraform.tfvars`

Then install:

  $ tf init && tf apply --auto-approve

