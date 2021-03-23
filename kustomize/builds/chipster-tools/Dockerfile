FROM base

COPY tools /home/user/chipster-tools/tools
COPY manual /home/user/chipster-tools/manual

RUN ls -lah /home/user/chipster-tools \
  && ls -lah /home/user/chipster-tools/tools \
  && ls -lah /home/user/chipster-tools/manual

CMD ["sleep", "inf"]
