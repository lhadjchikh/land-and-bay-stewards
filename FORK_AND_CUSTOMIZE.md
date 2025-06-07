# Fork and Customize Guide

This project can be reused by other advocacy groups. Follow these steps after forking:

1. Clone your fork and copy `.env.example` to `.env`.
2. Update values in `.env` including `ORG_NAME`, `ORG_TAGLINE`, `CONTACT_EMAIL`, `DB_NAME`, and domain settings.
3. Edit `branding.json` if you want to change logos or default text.
4. Run `docker-compose up` to start development or follow `terraform/README.md` for cloud deployment.

With these variables customized, the app will display your organization name and use your infrastructure settings.
