
CREATE TABLE Adresse (
idAdresse NUMBER(10),
noAppartement VARCHAR2(10),
noCivil NUMBER(8),
nomRue VARCHAR2(100),
codePostal VARCHAR2(8),
ville VARCHAR2(100),
PRIMARY KEY (idAdresse)
);


CREATE TABLE Caution(
idCaution NUMBER(10),
prix NUMBER(10),
nbDvd NUMBER(10) DEFAULT 0,
PRIMARY KEY (idCaution),

/* L'abonnement comporte une caution
à 2$ par dvd, le prix est 2 fois le nb de DVD empruntable*/
CONSTRAINT ChkPrix CHECK (prix = 2 * nbDvd),

/* L'abonnement permet de 1 à 8 DVD en même temps*/
CONSTRAINT ChkNbDvd CHECK (nbDvd <= 8 AND nbDvd >= 0)
);


CREATE TABLE Client (
idClient NUMBER(10),
nomClient VARCHAR2(100),
prenomClient VARCHAR2(100),
telephoneClient VARCHAR2(50),
nbEmpruntEnCours NUMBER(2) NULL,
statutClient CHAR(1),
idCaution NUMBER(10),
idAdresse NUMBER(10),
FOREIGN KEY (idCaution) REFERENCES Caution,
FOREIGN KEY (idAdresse) REFERENCES Adresse,
PRIMARY KEY (idClient),
          
/* Le statut du client a seulement deux positions accepté 
Vrai(True(T)) ou Faux(False(F))*/                          
CONSTRAINT ChkStatutClient CHECK (statutClient IN ('F','T'))
);


CREATE TABLE Facture (
noFacture NUMBER(10),
dateEmission DATE,
idClient NUMBER(10),
PRIMARY KEY (noFacture),
FOREIGN KEY (idClient) REFERENCES Client
    ON DELETE CASCADE
);


CREATE TABLE Genre (
typeGenre VARCHAR2(200),
publicCible VARCHAR2(200),
PRIMARY KEY (typeGenre)
);


CREATE TABLE Film(
idFilm NUMBER(10),
dureeFilmMinute NUMBER(8,3),
PRIMARY KEY (idFilm)
);


CREATE TABLE Acteur(
idActeur NUMBER(10),
nomActeur VARCHAR2(100),
prenomActeur VARCHAR2(100),
PRIMARY KEY (idActeur)
);


CREATE TABLE Acteur_Film(
idActeur NUMBER(10),
idFilm NUMBER(10),
FOREIGN KEY (idActeur) REFERENCES Acteur
    ON DELETE CASCADE,
FOREIGN KEY (idFilm) REFERENCES Film
    ON DELETE CASCADE,
PRIMARY KEY (idActeur, idFilm)
);


CREATE TABLE Realisateur(
idRealisateur NUMBER(10),
nomRealisateur VARCHAR2(100),
prenomRealisateur VARCHAR2(100),
PRIMARY KEY (idRealisateur)
);


CREATE TABLE Magasin(
idMagasin NUMBER(10),
idAdresse NUMBER(10),
FOREIGN KEY (idAdresse) REFERENCES Adresse,
PRIMARY KEY (idMagasin)
);


CREATE TABLE Dvd(
noDvd NUMBER(10),
miseEnService DATE,
etatDisque VARCHAR2(100),
statutEmprunt CHAR(1),
nbLocation NUMBER(4),
idMagasin NUMBER(10),
idFilm NUMBER(10),
FOREIGN KEY (idMagasin) REFERENCES Magasin
    ON DELETE CASCADE,
FOREIGN KEY (idFilm) REFERENCES Film
    ON DELETE CASCADE,
PRIMARY KEY (noDvd),

/*statutEmprunt est VRAI(TRUE(T)) si est emprunter sinon FAUX(FALSE(F))*/
CONSTRAINT ChkStatutEmprunt CHECK (statutEmprunt IN ('F','T')),
CONSTRAINT ChkEtatDisque CHECK(etatDisque IN ('bad', 'good', 'perfect'))
);


CREATE TABLE Emprunt(
idEmprunt NUMBER(10),
noteFilmClient NUMBER(10) NULL,
dateEmprunt DATE,
dateRetour DATE NULL,
idClient NUMBER(10),
noDvd NUMBER(10),
FOREIGN KEY (idClient) REFERENCES Client,
FOREIGN KEY (noDvd) REFERENCES Dvd,
PRIMARY KEY (idEmprunt),

/* Les valeurs entrées doivent être positive ou egale a 0*/	
CONSTRAINT ChkIdPositif CHECK (idEmprunt >= 0),

/*La note donnée par un client entrée doit se trouver entre 0 et 100 inclusivement*/
CONSTRAINT ChkNote CHECK (noteFilmClient >= 0 AND noteFilmClient <= 100),

/* La date de retour doit être à l'intérieur de 7 jours apres dateEmprunt*/
CONSTRAINT ChkDateRetour CHECK (dateRetour <= dateEmprunt + 7)
);


/*Triggeur*/


/*assure que la date de mise en service soit avant la date d'emprunt*/
CREATE OR REPLACE TRIGGER servicePosterieurEmprunt
BEFORE UPDATE 
ON Emprunt
FOR EACH ROW
DECLARE service DATE;
BEGIN
    SELECT miseEnService
    INTO service
    FROM Dvd 
    Where('Dvd.noDvd' = 'Emprunt.noDvd');
  
    IF(:NEW.dateEmprunt < service)
      THEN :NEW.dateEmprunt := :OLD.dateEmprunt;
    END If;
END servicePosterieurEmprunt;
/

/*Avant qu'un client emprunte un DVD, une vérification est faite,
si le statut du client est actif, 
il y a une incrémentation aù nombre d'emprunt, il peut donc emprunter*/
CREATE OR REPLACE TRIGGER AvantUpdateClient
BEFORE UPDATE
ON Client
FOR EACH ROW

BEGIN
    
    IF(:OLD.statutClient IN ('T'))  
    THEN :NEW.nbEmpruntEnCours := :OLD.nbEmpruntEnCours+1;
    END If;
END AvantUpdateClient;
/


/*Le nbDvd de 0 est attribue aux membres n'ayant pas de caution. 
Ce qui fait en sorte qu'automatiquement leur statut d'emprunt devient False*/
CREATE OR REPLACE TRIGGER TrgChkStatutClient
BEFORE INSERT
On client

FOR EACH ROW

BEGIN

update Client
set statutClient = 'F'
Where (SELECT nbDvd
FROM Caution
Where Caution.idCaution = Client.idCaution) = 0;

END TrgChkStatutClient;
/


/*test des contraintes*/



/* Emprunt rejete car idEmprunt negatif et noteFilmClient trop haute */
INSERT INTO Emprunt
(idEmprunt, noteFilmClient)
VALUES
(-42, 1234567890);

/*pour pouvoir tester insert into client*/
INSERT INTO CAUTION
(idCaution, prix, nbDvd)
VALUES(58, 4, 2);

INSERT INTO Adresse
(idAdresse, noAppartement, noCivil, nomRue, codePostal, ville)
VALUES(78, 3, 34, 'sup', 'j3b3t6', 'Saint-Remis');

/* La valeur w n'est pas comforme dans le statusClient (F ou T)*/
INSERT INTO CLIENT
(idClient, nomClient, prenomClient,telephoneClient, nbEmpruntEnCours, statutClient, IdCaution, IdAdresse)
VALUES(8, 'Tahiri', 'Nadia', '450-348-2667', 1, 'w', 58, 78);

/*pour pouvoir tester insert into client*/
INSERT INTO CAUTION
(idCaution, prix, nbDvd)
VALUES(55, 4, 2);

INSERT INTO Adresse
(idAdresse, noAppartement, noCivil, nomRue, codePostal, ville)
VALUES(77, 3, 34, 'sup', 'j3b3t6', 'Saint-Remis');

/* Toutes les données insérées
sont conformes aux champs respectif désirés,
le client est donc crée*/
INSERT INTO CLIENT
(idClient, nomClient, prenomClient,telephoneClient, nbEmpruntEnCours, statutClient, IdCaution, IdAdresse)
VALUES(84, 'Abdel-Nour', 'Georgio', '450-347-7219', 2, 'T', 55, 77);

/* La base de donnée acceptera l'insertion, mais viendra
mettre le statut client à faux donc inactif*/
INSERT INTO Caution
(idCaution, prix, nbDvd)
VALUES(0, 0, 0);

/*rejete car le prix n'est pas = a 2 * le nbDvd. De plus, nbDvd trop haut*/
INSERT INTO Caution
(idCaution, prix, nbDvd)
VALUES(1,56,89);

/*rejete car idEmprunt negatif,
noteFilmClient trop haute, dateEmprunt apres dateRetour*/
INSERT INTO Emprunt
(idEmprunt, noteFilmClient, dateEmprunt, dateRetour)
VALUES(-9, 234567, '1998-08-25', '1997-08-25');

/*rejette car etatDisque et statutEmprunt pas format accepte,*/
INSERT INTO Dvd
(NoDvd, miseEnService, etatDisque, statutEmprunt, nbLocation)
VALUES(34, '1999-01-01', 'piteux', 'H',67);

/*accepter*/
INSERT INTO Dvd
(NoDvd, miseEnService, etatDisque, statutEmprunt, nbLocation)
VALUES(12, '2020-02-19', 'good', 'T', 5);

/*accepter*/
INSERT INTO Emprunt
(idEmprunt, noteFilmClient, dateEmprunt, dateRetour)
VALUES(0, 4, '2020-02-20', '2020-02-24');

