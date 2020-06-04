# Tower-Defense
Tower Defense mod to Counter-Strike 1.6

<a href="http://www.youtube.com/watch?feature=player_embedded&v=O-lF6o7ajxc
" target="_blank"><img src="http://img.youtube.com/vi/O-lF6o7ajxc/0.jpg" 
alt="Tower defense live" width="240" height="180" border="10" /></a>

Changelog (polish)
/* Wersja 0.1 Alpha */

- Pierwsze wydanie pluginu

/* Wersja 0.1 Alpha: Turrets Fix */

- Naprawienie drobnego błędu w wieżyczkach

/* Wersja 0.2 Alpha [Lato 2014] */

- Dodanie aktualnych map jako standardowe w tym modzie, czyli są w paczce
- Dodanie modułu hamsandwich (linux)
- Wgranie nowej wersji nieskończonej rundy działającej z najnowszymi binarkami(tylko)

/* Wersja 0.3 Alpha [Lato 2014] */

- Poprawienie wykonania komendy /start. Od teraz komendę może użyć¦ gracz, gdy na serwerze znajdują się 2 osoby.
- Dodanie pokazywania wymaganej liczby fragów w dziale "Umiejętności" w głównym menu.
- Drobne usterki i poprawki wyświetlanych tekstów.
- Poprawienie niekompilującego się pliku .sma
- Dodanie nowego include
- "Naprawienie" dźwięku "Start_Wave", który się w ogóle nie odtwarzał

/* Wersja 0.4 Beta [Lato 2014 - *przerwa* - Styczeń 2015] */

- Dodanie sklepu ( możliwość¦ dodawania własnych przez natyw td_shop_register_item )
- Dodanie itemów do sklepu (m. in. minigun, naprawa głównej wieży)
- Dodanie nowych spritów(ranger i ammobar - wymagane usunięcie folderu /sprites/TD w celu pobrania aktulanych z serwera)
- Dodanie paska amunicji nad wieżyczką, z nią cvar (0 - wyłącz|1-tylko właścicielowi|2-wszystkich)
- Dodanie komendy /daj i /przekaz, w niej również Menu Admina.
- Dodanie komendy /wymien i /swap ( zamienia $10000 na 10 zÂłota - cvary)
- Dodanie własnego menu broni ( własne ustawienia cen broni )
- Dodanie wyświetlania informacji o wieżyczce (jeśli blisko podejdziesz)
- Naprawa błędu z healthbarem
- Synchronizacja cvarów z plikiem konfiguracyjnym
- Dodanie mnóstwo nowych cvarów, od teraz TY decydujesz jak ma wyglądać¦ rozgrywka i sprawić¦, że mod bęŞdzie unikalny
- Dodanie nowych natywów i forwardów [Dla Skrypterów]
- Dodanie odliczania dźwiękowego [Opcjonalnie]
- Zmiejszenie wymaganych fragów za dany poziom
- Dodanie złota za określoną liczbę zadanych obrażeń
- Dodanie złota oraz kasy za przetrwanie wavu
- Usunięcie problemów przy rozpoczęciu gry
- Naprawa set_tasków, usunięcie problemu przy modernizacji wieżyczek
- Nowy styl modernizowania, ulepszania, kupowania wieżyczek, od teraz to nie trwa tak szybko
- Dodanie zaawansowanego systemu Asyst [Opcjonalnie]
- Dodanie multi-language do pluginu [Aktualnie PL-EN]
- Usunięcie pluginu nieskonczonej rundy jako dodatkowy plugin

Optymalizacje :
- Zamienienie fakemety na engine - szybkość¦ działania modu
- Dodanie cvar_util, od teraz maksymalne wartości jakie mogą być nigdy nie zostaną przekroczone 
- Event Money
- Ogromne poprawki i optymalizacje różnych funkcji - w tym PreThinki i Thinki
- Zmiana systemu odliczania - Łatwiejszy, krótszy, szybszy
- Estetyka kodu - Łatwość odczytania


/* Wersja 0.5 Beta [Lipiec 2015] */
/* WGRYWAJĄC TĄ WERSJE KONIECZNIE PODMIEŃ MODELE NA SERWERZE */ 
- Zwiększenie standardowych wavów do 35, oraz wzmmocnienie potworów
- Zwiększenie prawdopodobnieństwa wystąpienia krwi po strzale
- Dodanie do sklepu granatów podpalających
- Dodanie do sklepu amunicji dla miniguna
- Dodanie do sklepu AWP z 2x obrażeniami
- Dodanie do sklepu złotych naboi
- Dodanie do sklepu granatów spowalniających
- Naprawa kilku wyświetlanych tekstów (m. in. odliczanie)
- Dodanie możliwość zdobycia $$$ za określoną liczbę zadanych obrażeń
- Usunięcie zbugowanego modelu "pielęgniarki", którą ciężko było trafić
- Optymalizacja parametrów konfiguracyjnych serwer Tower Defense
- Naprawienie miniguna w sklepie
- Naprawienie otrzymywanej ilości złota i kasy po dołączeniu na serwer podczas trwania X wavu
- Naprawienie taska odpowiedzialnego za wysyłanie potworów
- Dodanie nowej mapy: td_big jako jedna z podstawowych map do Tower Defense Mod
- Naprawienie wyświetlającego się tekstu multi-language w nazwach rund. Od teraz wyświetlają się poprawnie.
- Dodanie nowej mapy: td_striker jako jedna z podstawowych map do Tower Defense Mod
- Zwiększenie liczby wavów w pliku standard_wave, oraz dodanie opcjonalnej trudniejszej wersji
- Dodanie nowych natywów i forwardów [Dla Skrypterów]
- Edytowanie systemu sklepu. Od teraz doszedl nowy plik konfiguracyjny "td_shop.cfg", do którego automatycznie przez plugin 
zostają dopisane właściwości każdego itemu ze sklepu, które możemy dowolnie zmieniać
- Dodanie nowego pluginu "td_hs_damage" - 1.5x większe obrażenia po trafieniu w głowe [Opcjonalnie]
- Dodanie nowego pluginu "td_sprite_engine", oraz "td_sprite_ammo"[oba muszą być włączone], które dodają do hudu wyświetlające się sprity
związane ze statusem wieżyczki w ilości amunicji [Opcjonalnie]
- Poprawki wyświetlanych tekstów
- Dodanie więcej tekstów multi-language
- DEBUG MODE zostalo rozszerzone i usprawnione
- DEBUG MODE jest od teraz angielskie
- Dodano klasy ludzi. Doszedł nowy plik konfiguracyjny "td_class.cfg" tworzony automatycznie przez plugin,
wartości w nim można dowolnie zmieniać
- Zmieniono ścieżkę oraz system wczytywania ustawień wieżyczek. Od teraz do każdej mapy możesz inaczej dostosować ustawienia wieżyczek.
- Ulepszono system ulepszenia wieżyczek. Od teraz możesz dodać nieograniczoną ilośc ulepszeń obrażen i zasięgu
- Naprawiono komendę [LOAD_STANDARD_WAVE]
- Dodano plugin odpowiadający za głosowanie na następną mapę, wraz z nią cvary
- Poprawiono modele potworów. Zostały zwiększone hitboxy głowy, przez co łatwiej trafić w głowę i zadać więcej obrażen
- Zwiększono czytelność kodu obu silników oraz przeprowadzono drobne poprawki w nazewnictwie
- Usunięto bug z td_guns, w związku z kupywaniem amunicji poza buyzone
- Dodano VIPA! Wraz z nimi nowe cvary
- Dodano (przy zadawaniu obrażeń) informacje, czy strzał byl heashotem
- Dodano animacje śmierci potworów, kiedy zostały zabite headshotem
- Zmieniono system przechodzenia przez enty, dzięki czemu można potwory spowalniać
- Dodano model VIPA
- Dodano modele graczy 
- Dodano nowe dźwięki odtwarzające się podczas "czekania" na następny wave. (odtwarzane w pobliżu respawna potworów)

/* End of Changelog */

AKTUALNA LISTA MAP DOSTĘPNA: http://cs.gamebanana.com/maps/cats/8329
