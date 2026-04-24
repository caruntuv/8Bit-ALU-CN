README / Log de realizare proiect – 8 Bit ALU
1. Prezentarea proiectului

Proiectul reprezintă implementarea unei unități aritmetico-logice pe 8 biți, denumită 8 Bit ALU, realizată în limbajul Verilog. Scopul proiectului a fost construirea unei structuri capabile să execute mai multe operații aritmetice de bază asupra a doi operanzi pe 8 biți.

Operațiile implementate sunt:

adunare;
scădere;
înmulțire;
împărțire.

În versiunea finală, proiectul este organizat pe mai multe module Verilog, fiecare având un rol clar. Modulul principal este alu_8bit.v, care leagă toate componentele între ele și coordonează funcționarea generală a sistemului.

2. Etapa inițială a proiectului

La început, proiectul a fost realizat prin implementarea blocurilor de bază. Prima dată au fost construite modulele pentru operațiile aritmetice principale.

Pentru adunare a fost realizat modulul adder_8bit.v, construit pe baza mai multor module full_adder.v. Fiecare full_adder calculează suma pentru un singur bit, iar prin legarea lor în lanț se obține un adunător pe 8 biți de tip Ripple Carry Adder. Carry-ul rezultat de la un bit este transmis către următorul bit, până la bitul cel mai semnificativ.

Scăderea a fost realizată în modulul subtractor_8bit.v, folosind tot adunătorul. Ideea folosită este scăderea prin complement față de 2:

A - B = A + (~B) + 1

Astfel, nu a fost nevoie de un circuit complet separat pentru scădere, ci s-a refolosit modulul de adunare.

Pentru înmulțire a fost ales algoritmul Booth Radix-2, implementat în modulul booth_multiplier.v. Acesta a fost ales deoarece este o variantă relativ simplă de implementat pentru înmulțirea numerelor binare și permite tratarea mai clară a cazurilor cu semn.

Pentru împărțire, în arhiva finală apare modulul restoring_divider.v, care implementează împărțirea prin pași succesivi, folosind registre interne, scădere și actualizarea câtului și restului.

3. Prima variantă de implementare

În prima variantă a proiectului, acolo unde era nevoie de logică secvențială, au fost folosite blocuri always. Această abordare a făcut codul mai ușor de scris și de înțeles.

Modulele compilau și funcționau pentru valorile alese în testare. ALU-ul putea executa operațiile de bază, însă testbench-urile finale nu erau încă implementate complet sau uniform pentru toate situațiile.

Această versiune a fost utilă pentru verificarea ideii generale a proiectului, deoarece a permis testarea rapidă a funcționării modulelor.

4. Trecerea la implementare structurală

Ulterior, s-a aflat că proiectul trebuie realizat într-o formă cât mai structurală. Din acest motiv, mai multe module au trebuit reconstruite.

Implementarea structurală înseamnă că funcționarea circuitului este descrisă prin legarea unor componente mai mici între ele, folosind porți logice, fire interne, registre și instanțieri de module, nu prin descrieri comportamentale complexe în blocuri always.

În varianta finală, singurul modul care folosește always este:

dff_posedge.v

Acesta implementează un flip-flop de tip D pe front pozitiv de ceas:

always @(posedge clk) q <= d;

Acest flip-flop este apoi folosit peste tot unde este nevoie de memorare.

5. Modulele principale din proiect
-full_adder.v

Acesta este cel mai simplu bloc aritmetic. Primește doi biți, a și b, plus un carry de intrare cin, și produce suma sum și carry-ul de ieșire cout.

Este realizat structural, cu porți logice xor, and și or.

-adder_8bit.v

Modulul adder_8bit construiește un adunător pe 8 biți folosind 8 module full_adder.

Carry-ul trece de la un bit la altul, motiv pentru care acest adunător este de tip Ripple Carry Adder.

Modulul are și semnalul enable, care controlează dacă ieșirea este activă sau pusă în stare high-impedance.

-subtractor_8bit.v

Modulul subtractor_8bit realizează scăderea folosind adunătorul. Mai întâi inversează biții lui B, apoi adaugă valoarea 1 prin Cin.

Rezultatul este diferența Diff, iar semnalul Bout indică apariția unui împrumut.

-register_8bit.v

Modulul register_8bit este un registru pe 8 biți. Acesta este construit din 8 instanțe ale modulului dff_posedge.

Are semnale de control pentru:

load – încărcarea unei valori noi;
rst – resetarea registrului;
oe – activarea ieșirii.

Acest modul este important deoarece permite memorarea operanzilor și a rezultatului în interiorul ALU-ului.

-booth_multiplier.v

Modulul booth_multiplier implementează înmulțirea folosind algoritmul Booth Radix-2.

Acesta folosește mai multe registre interne:

A – acumulator;
QQ – registru pentru multiplicator și bitul suplimentar;
M_reg – valoarea memorată a operandului;
count – contor pentru numărul de pași;
Product_r – produsul final memorat;
running și done_r – semnale pentru controlul execuției.

În această variantă structurală, modulul a devenit mult mai complicat, deoarece nu mai este descris simplu printr-un bloc always, ci prin porți logice, fire interne, multiplexări și blocuri generate.

-restoring_divider.v

Modulul restoring_divider implementează împărțirea. Acesta calculează câtul și restul pentru doi operanzi pe 8 biți.

Ieșirile principale sunt:

Quotient – câtul;
Remainder – restul;
done – semnal de finalizare;
div_by_zero – semnal pentru cazul împărțirii la zero.

Și acest modul a devenit mai complex în varianta structurală, deoarece folosește registre interne, scădere, contor și logică de control construită prin porți și blocuri generate.

-control_unit.v

Modulul control_unit este unitatea de control a proiectului. Aceasta funcționează ca un Finite State Machine, adică o mașină cu stări finite.

Stările principale sunt:

S_IDLE – așteaptă pornirea operației;
S_LOAD – încarcă operanzii în registre;
S_EXEC – pornește operația;
S_WAIT – așteaptă finalizarea operațiilor mai lente;
S_STORE – salvează rezultatul;
S_DONE – semnalează finalizarea operației.

Unitatea de control decide ce modul trebuie activat în funcție de semnalul op:

00 – adunare;
01 – scădere;
10 – înmulțire;
11 – împărțire.

Pentru adunare și scădere, rezultatul se obține rapid. Pentru înmulțire și împărțire, unitatea de control așteaptă semnalele mul_done și div_done.

-alu_8bit.v

Modulul alu_8bit este top level-ul proiectului. Acesta leagă toate modulele principale:

register_8bit pentru RA, RB și RC;
adder_8bit;
subtractor_8bit;
booth_multiplier;
restoring_divider;
control_unit;
dff_posedge.

În acest modul, operanzii A_in și B_in sunt încărcați în registrele interne RA și RB. Apoi, în funcție de operația aleasă, se activează modulul corespunzător. Rezultatul este salvat în registrele de rezultat RC_hi și RC_lo, apoi este transmis pe ieșirea OUTBUS.

6. Testarea proiectului

Pentru verificare au fost realizate mai multe testbench-uri:

tb_adder_8bit.v;
tb_subtractor_8bit.v;
tb_booth_multiplier.v;
tb_restoring_divider.v;
tb_alu_8bit.v.

Testbench-ul pentru ALU verifică operațiile principale:

10 + 20;
255 + 1;
20 - 10;
10 - 20;
5 * 3;
0 * 25;
20 / 4;
22 / 5.

De asemenea, există și câteva teste random pentru verificarea generală a funcționării.

Pentru Linux a fost adăugat și scriptul:

run_all.sh

Acesta compilează și rulează simulările folosind Icarus Verilog și generează fișiere .vcd, care pot fi analizate în GTKWave.

7. Probleme întâlnite

O dificultate importantă a fost rularea simulărilor pe sisteme de operare diferite.

Pe Windows s-a folosit ModelSim, program utilizat și la materia Arhitectura Calculatoarelor. Pe Linux s-au folosit Icarus Verilog și GTKWave.

Au existat mici diferențe între testbench-urile folosite pe Windows și cele folosite pe Linux. De asemenea, în versiunea pentru Linux a fost folosit un script shell pentru compilare și rulare automată.

O altă dificultate a fost trecerea de la implementarea cu always la implementarea structurală. Modulele de înmulțire, împărțire, control unit și top level au trebuit refăcute, iar codul a devenit mai lung și mai greu de urmărit.

8. Organizarea pe GitHub

Proiectul a fost lucrat colaborativ pe GitHub.

Cele două versiuni principale au fost păstrate pe branch-uri diferite:

versiunea pentru Linux a fost pusă pe branch-ul main;
versiunea pentru Windows a fost pusă pe un branch alternativ.

Această organizare a permis păstrarea ambelor variante, deoarece existau diferențe mici între mediile de simulare și între testbench-uri.

9. Diagrame și documentare

Pentru o înțelegere mai ușoară a sistemului, au fost realizate și diagrame explicative. Acestea ajută la vizualizarea legăturilor dintre module și la înțelegerea modului în care datele trec prin ALU.

Codul a fost ulterior comentat, astfel încât fiecare semnal și fiecare bloc important să fie mai ușor de înțeles.

10. Concluzie

Proiectul 8 Bit ALU a pornit de la o implementare mai simplă, bazată pe blocuri always, și a fost transformat ulterior într-o implementare structurală.

Această schimbare a făcut proiectul mai dificil, dar și mai apropiat de modul real în care poate fi descris un circuit digital la nivel de componente.

În final, proiectul conține o ALU pe 8 biți care poate executa adunare, scădere, înmulțire și împărțire, folosind module separate, o unitate de control de tip FSM, registre interne și un top level care le conectează pe toate.
