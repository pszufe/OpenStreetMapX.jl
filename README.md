# OSMsim.jl
OpenStreetMap - routing and simulations library

## Installation

The current version uses JuliaPro 0.6.4

Before using the library you need to install Julia packages:

```julia
Pkg.add("Winston")
Pkg.add("Distributions")
Pkg.add("DataFrames")
```

Once the packages are installed you need to replace the *tkwidget.jl* file that can be found (assuming a default JuliaPro installation) at: 

```
C:\JuliaPro-0.6.4.1\pkgs-0.6.4.1\v0.6\Tk\src\tkwidget.jl
```

Please use the tkwidget.jl [supplied in this project](https://github.com/pszufe/OSMsim.jl/raw/master/tkwidget.jl_for_replacement/tkwidget.jl). 





## TODOs



(TODO: Ania tide up the list and translate to English)

1. Buffering - jeżeli jakaś droga już była wyznaczona - to easy - dodać do statystyk
2. Additional activity dodać waypoints - najpierw jedzie before tam gdzie po drodze

 Step 4 Calculate stats for each given intersection
 function agentProfileAgregator
   a) DA distribution   (simplified)
   b) demographic distribution (if demographic profile determines moving patterns)
        - we have agreed to leave out that scenario for a while

 ISSUES

- women work in constructions?
- DemoProfile: każda zmienna z innej parafii... --> są liczone dla różnych grup wiekowych, raz dla household,
  raz per osobę,raz per osobę w wieku 15+, dzieci tylko dla par lub samotnych, a raz w ogóle nie wiadomo jak to liczą...
- vehicles nie uwzględniamy bo są DA gdzie liczba samochodów jest wysoce sprzeczna z census data

 50% of hh do not have children

 jak optymalnie sie robi ze zbiorem? tuż po wylosowaniu agenta filtruje df_demostat?

 @where w query --> df_recreationComplex

 !!! shopping centres - nowy dataset by się przydał

 żeby jakos do agregowania dodac visited places

 optymalizacja dróg --> A + B + C / A + C jak najmniejsze --> i to determinuje też wybór punktów

 recreation probabilities

 żeby wybierać add activities bardziej po drodze

 jakiś error handling?

 eksport wykresy w dobrej jakości

 ECEF (ja) ENU (Bartek)

 schools - mozna dodać warunek na min dist - że pieszo idę

 add activity  - wyfiltrowałam max 1 przed i max 1 po

 ??? H - before - W - after - H ?



## 



