---
title: "Dalla Firma alla Fiducia: Assicurare la Sicurezza delle Immagini Docker con Cosign"
category: Container
description: Scopri come Cosign può aiutarti a instaurare un ambiente di fiducia attorno alle tue immagini Docker attraverso la firma digitale, con esempi pratici su come implementare questo processo nella tua pipeline GitHub.
image: cosign/cover.png
keywords: cosign-sigstore, firma-immagini-docker, sicurezza-supply-chain-software, verifica-immagini-docker, integrazione-cosign-github
layout: post
date:   2023-10-10
---

Nel vasto e dinamico ecosistema dello sviluppo software, la sicurezza è un pilastro fondamentale che garantisce l'affidabilità e l'integrità dei prodotti digitali. In particolare, con la crescente adozione dei container, la necessità di validare l'autenticità e l'integrità delle immagini Docker è diventata cruciale. Qui entra in gioco [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/), uno strumento sviluppato dal progetto [**_Sigstore_**](https://www.sigstore.dev/), progettato per facilitare la firma e la verifica delle immagini Docker. Questa pratica assicura che il codice che si sta per distribuire sia esattamente quello inteso, privo di alterazioni malevole. In questo articolo, ci immergeremo nel mondo di [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/), esplorando come funziona, come può essere utilizzato per firmare un'immagine Docker, e perché è un elemento essenziale per migliorare la sicurezza della supply chain del software. Illustrerò anche un esempio pratico, mostrando come ho integrato [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) in una pipeline GitHub per automatizzare il processo di firma delle immagini. Per una visione dettagliata e l'accesso al codice sorgente, vi invito a visitare il mio [repository GitHub](https://github.com/paranoiasystem/testcosign).

---

## Cos'è Cosign?

[**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/), uno strumento del progetto [**_Sigstore_**](https://www.sigstore.dev/), nato con l'obiettivo di rendere la firma e la verifica delle immagini Docker un processo semplice e sicuro. Questo strumento è vitale per assicurare che il codice lanciato in produzione sia l'esatta replica del codice originale, libero da modifiche malevole. Grazie a pochi e semplici comandi, [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) democratizza l'uso della crittografia a chiave pubblica, rendendola alla portata anche di team con competenze di base in sicurezza informatica. Oltre alla firma e verifica, [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) si spinge oltre, offrendo trasparenza delle chiavi e delle firme, facilitando così la verifica delle firme e garantendo che nessuna modifica alle immagini firmate possa passare inosservata. Questa robusta funzionalità posiziona [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) come uno strumento imprescindibile nella toolbox di ogni DevOps attento alla sicurezza, fornendo una linea di difesa robusta contro gli attacchi alla supply chain del software.

## Perché è Utile la Firma delle Immagini Docker?

La firma delle immagini Docker è un passo cruciale verso la creazione di una supply chain del software sicura. Questa pratica eleva la barriera contro minacce potenziali, garantendo l'autenticità e l'integrità dei container. Funge da meccanismo di verifica robusto, assicurando che il codice pronto per l'esecuzione o la distribuzione sia esattamente quello originale, immune da modifiche malevole o non autorizzate. La firma delle immagini Docker si rivela essenziale per prevenire attacchi Man-in-the-Middle (MitM), dove gli aggressori possono tentare di iniettare codice malevolo durante il transito delle immagini attraverso la rete. Inoltre, contribuisce alla facilitazione di audit e conformità, offrendo un registro immutabile delle immagini firmate e verificate, fornendo così una tracciabilità completa e una responsabilità chiara. Questo è particolarmente utile in scenari regolamentati o ad alta sicurezza, dove la tracciabilità e la conformità sono cruciali. Con la crescita esponenziale degli ambienti containerizzati, la firma delle immagini Docker con [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) è diventata un elemento chiave per mantenere una supply chain del software sicura e resiliente, permettendo alle organizzazioni di operare con maggiore fiducia nell'integrità dei loro sistemi.

## Come Funziona Cosign?

[**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) opera generando una coppia di chiavi crittografiche: una chiave privata per la firma delle immagini Docker e una chiave pubblica per la verifica. Quando firmi un'immagine Docker con [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/), l'immagine e la firma vengono registrate in un registro di container. Successivamente, chiunque desideri verificare l'immagine può utilizzare la chiave pubblica per confermare che l'immagine sia stata firmata dalla chiave privata corrispondente e che non sia stata alterata. [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) può essere facilmente integrato in pipeline di CI/CD, permettendo la firma e la verifica automatica delle immagini durante il processo di distribuzione. Inoltre, [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) è in grado di interfacciarsi con il registro [**_Sigstore_**](https://www.sigstore.dev/) per una trasparenza delle firme ancor più robusta, offrendo una soluzione completa per gestire la sicurezza delle immagini Docker in una supply chain del software.

## Come Firmare un'Immagine Docker con Cosign

In questa sezione, illustreremo come firmare un'immagine Docker con [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) utilizzando una GitHub Action. Prima di iniziare, assicurati di avere installato l'ultima versione di [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/). Puoi scaricare il binario da GitHub o installarlo tramite Homebrew:

```bash
brew install cosign
```

Dopodiché, crea un token su GitHub ed esportalo come variabile d'ambiente:

```bash
export GITHUB_TOKEN=<token>
```

Ora, generiamo le chiavi che utilizzeremo nella GitHub Action. Grazie al token precedentemente esportato, il comando di [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) inserirà le chiavi generate nelle secret del progetto, permettendo il loro uso nella action:

```bash
cosign generate-key-pair github://<owner>/<project>
```

Prosegui creando la GitHub Action. Crea un file chiamato `docker-publish-and-sign.yml` nella cartella `.github/workflows` del tuo progetto, e inserisci il seguente codice:

<script src="https://gist.github.com/paranoiasystem/c43b3bc7f0cd7986832aedc0da96b3ce.js"></script>

Questa GitHub Action segue una sequenza precisa di operazioni per garantire che l'immagine Docker venga costruita, pubblicata e firmata in modo sicuro:

- **Checkout**: Recupera il codice sorgente dal repository GitHub.
- **Set up Docker Buildx**: Prepara l'ambiente per la costruzione dell'immagine con Docker Buildx.
- **Installazione di Cosign**: Installa [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) nell'ambiente di esecuzione il quale servirà la firma dell'immagine.
- **Login al GitHub Container Registry**: Effettua il login al GitHub Container Registry (GHCR) per poter pubblicare l'immagine Docker.
- **Costruzione e Pubblicazione**: Costruisce e pubblica l'immagine Docker sul GHCR, utilizzando l'ID dell'esecuzione GitHub come tag dell'immagine.
- **Firma dell'Immagine**: Firma l'immagine Docker utilizzando la chiave privata, e la firma viene registrata nel registro.

Per verificare l'immagine firmata, esegui il seguente comando:

```bash
cosign verify --key <public-key> <image>
```

## Il Progetto Sigstore
[**_Sigstore_**](https://www.sigstore.dev/) è un progetto opensource che mira a elevare la sicurezza della supply chain. Nasce con l'obiettivo di fornire strumenti affidabili e trasparenti per la firma e la verifica di artefatti software. [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/) rappresenta una delle soluzioni offerte da [**_Sigstore_**](https://www.sigstore.dev/), fornendo un metodo sicuro e trasparente per firmare e verificare immagini Docker e altri artefatti. L'iniziativa [**_Sigstore_**](https://www.sigstore.dev/), sostenuta da una comunità attiva e collaborativa, si impegna costantemente nell'innovazione, cercando di rendere la supply chain del software più resiliente agli attacchi e conforme alle migliori pratiche di sicurezza.

## Conclusioni
L'integrità della supply chain del software è un requisito fondamentale per garantire la sicurezza nell'era moderna dello sviluppo software. Strumenti come [**_Cosign_**](https://docs.sigstore.dev/signing/quickstart/), supportati da iniziative come [**_Sigstore_**](https://www.sigstore.dev/), rappresentano passi avanti significativi verso la creazione di una supply chain più robusta e sicura, fornendo ai professionisti DevOps gli strumenti necessari per mitigare efficacemente i rischi associati agli attacchi alla supply chain.

---

Se hai seguito l'articolo fino a questo punto, ora dovresti avere una comprensione chiara su come firmare le tue immagini Docker e come verificarle. Spero che questo articolo ti sia tornato utile, e se hai domande o suggerimenti, non esitare a [contattarmi](https://www.linkedin.com/in/marcoferraioli93/).

