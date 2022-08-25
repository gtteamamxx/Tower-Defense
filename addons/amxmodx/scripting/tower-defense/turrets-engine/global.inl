#if defined _towerdefense_turrets_global_included
  #endinput
#endif
#define _towerdefense_turrets_global_included

// turrets configuration
new Trie:g_TurretInfoTrie;

// turrets registration
new Trie:g_RegisteredTurretsTrie;

// bools
new g_AreTurretsAvailable;

// initializes all global variables
public initGlobalVariables()
{
    // initialize dictionary for all turrets
    g_TurretInfoTrie = TrieCreate();

    // initialize dictionary for all registered turrets
    g_RegisteredTurretsTrie = TrieCreate();
}