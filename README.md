# install_azcopy.sh

Faz o download do azcopy v10 a partir de um link externo e instala o binário do programa no path /usr/bin/azcopy.

# CopyBlob.sh

Script criado para realizar uploads de arquivos a partir de um host Linux, com destino a um container blob criado em uma storage account do Azure.

O script utiliza o azcopy v10 para fazer a cópia dos arquivos.

## Passos para realizar a configuração do script:

1. Criar uma storage account no azure, de preferência "StorageV2"
    - Acrescentar o nome da storage account na váriavel `STORAGE`.

2. Criar um SAS Token que permita escrita e leitura no blob.

    A partir do Azure, acessar **Storage Accounts > yourstorage > Shared Access Signature**:

    - Em **Allowed resource types**, marcar a opção **container**
    - Em **Allowed permitions**, marcar todas as permissões para blob.
    - Em **Start and expiry date/time** definir a validade do SAS.
    - gerar o SAS com **Generate SAS and connection string**.
    - Por fim, com o SAS gerado, copiar o **SAS token** e acrescentar na váriavel `SAS` dentro do script.

4. Definir o nome do container, e acrescentar na váriavel `CONTAINER`.
    - Caso o container ainda não esteja criado, ele será gerado automaticamente pelo script.

5. Definir o Diretório de origem dos arquivos na váriavel `SOURCE_DIR`.

6. Definir o caminho dentro do container ná váriavel `BLOB_PATH`.
    - O caminho que será criado dentro do container para discernir entre os diferentes hosts backpeados


## Funcionamento do script

No código abaixo, o comando find gera uma lista de arquivos que é armazenada na várivel `$FILES`, essa váriavel vai conter todos os arquivos que começam com log no diretório `$SOURCE_DIR`.

O comando find pode ser modificado, caso haja a necessidade de buscar um outro padrão de arquivos.

O comando `for` irá percorrer a lsita de arquivos, e copiar cada arquivo com o comando `azcopy`. O `azcopy` pode ser instalado com o comando `install_azcopy.sh` que está disponível nesse repositório.

A opção `--overwrite ifSourceNewer`, evita que duas cópias do mesmo arquivo ocorram, já que entende, que caso haja um arquivo no blob com o mesmo nome e com uma data de modificação posterior, a cópia não é necessária.

Com isso o script pode ser configurado para funcionar em um espaço de tempo curto, já que tem o controle da data de modificação do arquivo e não fará cópias desnecessárias.

```
Main(){
    # Ensure that the log folder is created
    mkdir -p /var/log/azcopy

    # Make a container
    azcopy make $CONT_LINK >> $LOG_FILE

    # Create a variable with all files
    FILES=$(find $LOG_DIR -iname 'log*')

    # Copy all *.log files of a directory to a blob container.'
    GenTitle "START BACKUP"

    for PATH_FILE in $FILES; do
        GenLink $PATH_FILE
        echo >> $LOG_FILE && GenLog "Starting copy for $PATH_FILE:"
        azcopy copy --overwrite ifSourceNewer $PATH_FILE $LINK >> $LOG_FILE
    done
```

Para gerar cada blob, utilizei a função GenLink, que cria uma estrutura de arquivos baseada na data do arquivo, e na váriavel `$BLOB_PATH`.

```
GenLink(){
    YEAR=$(date -r $1 +%Y)
    MONTH=$(date -r $1 +%B)
    DATE=$(date -r $1 +%F)

    FILE=$(echo $1 | awk -F/ '{print $NF}')
    LINK="https://$STORAGE.blob.core.windows.net/$CONTAINER/$BLOB_PATH/$YEAR/$MONTH/$DATE/$FILE$SAS"
}
```

Com isso, a função gera uma estrutura dentro do blob, utilizando primariamente o $BLOB_PATH e depois separa os arquivos por ano, mês e dia. Essas datas são geradas utilizando o último histórico de modificação do arquivo.

Para remover os arquivos antigos, o bloco de código a baixo é utilizado:

```
    # Remove file whith modification time greater than 24h, and already available on the blob.
    GenTitle "REMOVE OLD FILES"

    RM_FILES=$(find $SOURCE_DIR -iname 'log*' -mtime +0)

    for PATH_FILE in $RM_FILES; do
        GenLink $PATH_FILE
        LINK_TEST=$(azcopy ls $LINK)
        if test -n "$LINK_TEST"; then
            GenLog "$PATH_FILE exist in blob, removing from local folder"
            GenLog $(rm -v $PATH_FILE)
        fi
    done
```

O funcionamento do comando find é bem parecido com o que foi apresentado a cima, utiliza o `$SOURCE_DIR` para gerar a lista de arquivos, porém com a opção `-mtime +0`, busca somente arquivos gerados a mais de 24h.

Com isso, mantemos sempre os arquivos gerados a menos de 24 horas no `$SOURCE_DIR` do sistema.

Essa opção pode ser alterada para diminuir ou aumentar a retenção dos arquivos.

Com a lista de arquivos gerada, o comando `azcopy ls $LINK` verifica a existência do arquivo no blob, e caso receba uma resposta, o arquivo será removido do host local.

## LOGS

Os logs são gerados diariamente no diretório /var/log/azcopy com a syntax "azcopy_YYYY-MM-DD.log".

## CRONTAB

A configuração no crontab pode ser realizada em qualquer horário, dependendo é claro do momento que os arquivos são gerados no sistema, e a retenção desejada.

Exemplo:

```
# Run CopyBlob_log every hour at mnute 00
00 * * * * /scripts/CopyBlob_log.sh
```