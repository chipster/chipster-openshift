FROM base

COPY tools /home/user/mylly-tools/tools
COPY manual /home/user/mylly-tools/manual

RUN ls -lah /home/user/mylly-tools \
  && ls -lah /home/user/mylly-tools/tools \
  && ls -lah /home/user/mylly-tools/manual

CMD ["sleep", "inf"]
