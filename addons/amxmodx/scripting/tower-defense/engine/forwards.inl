#if defined td_engine_forwards_includes
  #endinput
#endif
#define td_engine_forwards_includes

new g_ForwardOnConfigurationLoad;

public registerForwards()
{
    g_ForwardOnConfigurationLoad = CreateMultiForward("td_on_configuration_load", ET_CONTINUE, FP_ARRAY, FP_CELL);
}

public executeOnConfigurationLoadForward(configurationFilePath[128], bool:isGamePossible)
{
    new iRet;
    ExecuteForward(
        g_ForwardOnConfigurationLoad, 
        iRet, 
        PrepareArray(configurationFilePath, 
        charsmax(configurationFilePath), 0), 
        isGamePossible
    );
}