FROM nginx:stable

COPY start.sh .

ENTRYPOINT [ "./start.sh" ]
