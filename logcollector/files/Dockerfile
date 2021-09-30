FROM python
RUN pip install elasticsearch
RUN pip install kubernetes
COPY . /main
WORKDIR /main
RUN chmod a+x ./script.sh
CMD ["./script.sh"]
