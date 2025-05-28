ARG BASE_IMAGE

FROM $BASE_IMAGE

ENV PLAYWRIGHT_BROWSERS_PATH=opt/pw-browsers

RUN npx playwright install chromium --with-deps
