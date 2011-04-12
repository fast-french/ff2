/*********************************************************************/
/** Nom :              cmda_utils
/** Date de cr�ation : 08/08/2010 13:23:08
/** Version :          1.0.0
/** Cr ateur :         Peluso Loup
/***************************** ChangeLog *****************************/
/** V1.0.0 (par Peluso Loup) :
/**      Fonctions utilitaires pour le syst�me de commande.
/*********************************************************************/

/***************************** INCLUDES ******************************/

#include "stda_strtokman"
#include "cmda_constants"

/***************************** PROTOTYPES ****************************/

// DEF IN "cmda_utils"
// Fonction qui renvoie la premi�re commande trouv�e dans un cha�ne.
//   > string sSpeech - Cha�ne � scanner.
//   o struct cmd_data_str_loc - Structure contenant le speech et la position des tokens de la commande � tra�ter.
struct cmd_data_str cmdGetFirstCommand(string sSpeech, string sOriginalSpeech = "", int iRecursionDepth = 0, int iRecursionScale = 0);

// DEF IN "cmda_utils"
// Fonction qui d fini une structure pour stocker les informations d'une commande.
//   > string sSpeech - Speech d'origine.
//   > string sCommand - Commande r�cup�re.
//   > int iOpeningTokenPosition - Position du token d'ouverture.
//   > int iClosingTokenPosition - Position du token de fermeture.
//   o struct cmd_data_str - Commande � tra�ter.
struct cmd_data_str cmdSetDataStructure(string sSpeech = CMD_EMPTY_SPEECH, string sCommand = CMD_EMPTY_COMMAND_DATAS, int iOpeningTokenPosition = STD_TOKEN_POSITION_ERROR, int iClosingTokenPosition = STD_TOKEN_POSITION_ERROR);

// DEF IN "cmda_utils"
// Fonction qui r�cup�re le nom de la commande � ex cuter.
//   > string sCommand - Commande � tra�ter.
//   o string - Nom de la commande.
string cmdGetCommandName(string sCommand);

// DEF IN "cmda_utils"
// Fonction qui r�cup�re la valeur d'un param tre d fini dans la commande.
//   > string sCommand - Commande � tra ter.
//   > string sName - Nom du param tre.
//   o string - Valeur du param tre.
string cmdGetParameterValue(string sCommand, string sName);

// DEF IN "cmda_utils"
// Fonction qui d termine si un param tre est pr sent dans la commande ou non.
//   > string sCommand - Commande � tra ter.
//   > string sName - Nom du param tre.
//   o int - FALSE si le param tre n'est pas pr sent,
//           TRUE si le param tre est pr sent.
int cmdIsParameterDefined(string sCommand, string sName);

// DEF IN "cmda_utils"
// Fonction qui informe d'une erreur dans la commande.
//   > object oPC - Personnage   informer.
//   > string sErrorMessage - Message d'erreur.
void cmdSendErrorMessage(object oPC, string sErrorMessage);

// DEF IN "cmda_utils"
// D termine la validit  d'une commande en fonction de sa structure de donn�e.
//   > struct cmd_data_str strCommandDatas - Structure de donn�e de la commande.
//   o int - TRUE si la commande est valide, FALSE sinon.
int cmdIsCommandValid(struct cmd_data_str strCommandDatas);

// Structure contenant les donn�es relatives � une commande.
struct cmd_data_str {
    string sSpeech;
    string sCommand;
    int iOpeningTokPos;
    int iClosingTokPos;
};

// D�finition d'une structure invalide.
struct cmd_data_str EMPTY_COMMAND_DATAS = cmdSetDataStructure();

/************************** IMPLEMENTATIONS **************************/

struct cmd_data_str cmdSetDataStructure(string sSpeech = CMD_EMPTY_SPEECH, string sCommand = CMD_EMPTY_COMMAND_DATAS, int iOpeningTokenPosition = STD_TOKEN_POSITION_ERROR, int iClosingTokenPosition = STD_TOKEN_POSITION_ERROR) {
    struct cmd_data_str srt;
    srt.sSpeech = sSpeech;
    srt.sCommand = sCommand;
    srt.iOpeningTokPos = iOpeningTokenPosition;
    srt.iClosingTokPos = iClosingTokenPosition;
    return srt;
}

struct cmd_data_str cmdGetFirstCommand(string sSpeech, string sOriginalSpeech = "", int iRecursionDepth = 0, int iRecursionScale = 0) {
    if (iRecursionDepth == 0) {
        sOriginalSpeech = sSpeech;
    }
    if (CMD_ENABLED == FALSE || iRecursionDepth++ > CMD_MAX_DEPTH) {
        return EMPTY_COMMAND_DATAS;
    }
    int iOpenTokPos = stdGetFirstTokenPosition(sSpeech, CMD_OPENING_TOKEN);
    int iClosTokPos = stdGetNextTokenPosition(sSpeech, CMD_CLOSING_TOKEN, CMD_OPENING_TOKEN, iOpenTokPos);
    if (iOpenTokPos == STD_TOKEN_POSITION_ERROR || iClosTokPos == STD_TOKEN_POSITION_ERROR) {
        return EMPTY_COMMAND_DATAS;
    }
    int iNextOpenTokPos = stdGetNextTokenPosition(sSpeech, CMD_OPENING_TOKEN, CMD_OPENING_TOKEN, iOpenTokPos);
    if (iNextOpenTokPos != STD_TOKEN_POSITION_ERROR) {
        if (iClosTokPos > iNextOpenTokPos) {
            string sStringAfterToken = stdGetStringAfterToken(sSpeech, CMD_OPENING_TOKEN_LENGTH, iOpenTokPos);
            iRecursionScale += (iOpenTokPos + CMD_OPENING_TOKEN_LENGTH);
            return cmdGetFirstCommand(sStringAfterToken, sOriginalSpeech, iRecursionDepth, iRecursionScale);
        }
    }
    string sCommand = stdGetStringBetweenTokens(sSpeech, iOpenTokPos, CMD_OPENING_TOKEN_LENGTH, iClosTokPos);
    sCommand = stdTrimAllSpaces(sCommand);
    return cmdSetDataStructure(sOriginalSpeech, sCommand, iRecursionScale+iOpenTokPos, iRecursionScale+iClosTokPos);
}

string cmdGetCommandName(string sCommand) {
    return stdTrimAllSpaces(stdGetStringBeforeToken(sCommand, stdGetFirstTokenPosition(sCommand, CMD_PARAMETER_TOKEN)));
}

string cmdGetParameterValue(string sCommand, string sName) {
    int iOpenParTokPos = FindSubString(sCommand, CMD_PARAMETER_TOKEN+sName);
    if (iOpenParTokPos == STD_TOKEN_POSITION_ERROR) {
        return CMD_EMPTY_PARAMETER;
    }
    int iDefParTokPos = stdGetNextTokenPosition(sCommand, CMD_DEFINITION_TOKEN, CMD_PARAMETER_TOKEN, iOpenParTokPos);
    if (iDefParTokPos == STD_TOKEN_POSITION_ERROR) {
        return CMD_EMPTY_PARAMETER;
    }
    int iEndParTokPos = stdGetNextTokenPosition(sCommand, CMD_PARAMETER_TOKEN, CMD_DEFINITION_TOKEN, iDefParTokPos);
    if (iEndParTokPos == STD_TOKEN_POSITION_ERROR) {
        return stdGetStringAfterToken(sCommand, GetStringLength(CMD_DEFINITION_TOKEN), iDefParTokPos);
    }
    return stdGetStringBetweenTokens(sCommand, iDefParTokPos, GetStringLength(CMD_DEFINITION_TOKEN), iEndParTokPos);
}

int cmdIsParameterDefined(string sCommand, string sName) {
    return (FindSubString(sCommand, CMD_PARAMETER_TOKEN+sName) != STD_TOKEN_POSITION_ERROR);
}

void cmdSendErrorMessage(object oPC, string sErrorMessage) {
    SendMessageToPC(oPC, sErrorMessage);
}

int cmdIsCommandValid(struct cmd_data_str strCommandDatas) {
    if (strCommandDatas.iOpeningTokPos == STD_TOKEN_POSITION_ERROR || strCommandDatas.iClosingTokPos == STD_TOKEN_POSITION_ERROR) {
        return FALSE;
    }
    return TRUE;
}
