1) Antes de dar o apply:
- Criar um par de chaves e preencher o nome no código
- Preencher o ID do security group do cluster (tem no output da criação do cluster)
- Preencher o ID de uma subnet pública da VPC do cluster (procuro na console)
- Alterar, via console, as configurações da subnet pública escolhida: ativar a opção "Atribuir endereço IPv4 automaticamente"
- Alterar as regras de saída do security group para acesso http e https via console (não sei se é necessário, eu precisei fazer isso quando instalei python e locust manualmente)
- Alterar as regras de entrada do security group com SSH para "meu IP" via console

2) Após o apply:
- Enviar [locustfile.py e auto_test.py](https://github.com/camilamedeir0s/tests-locust-sw):

  $ scp -i caminho/my-key.pem ./locustfile.py ubuntu@<<endereço-ec2>>:/home/ubuntu

- Acessar a EC2 com SSH
- Rodar o teste:

  $ python3 auto_test.py
