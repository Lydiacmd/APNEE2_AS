# APNEE 2 - Analyseur d'assignations

**Auteur :** Lydia Belabbas
**Date :** Novembre 2024  


---
### Compilation
```bash
make clean 
make
```

Cela génère l'exécutable `assign1`.

### Exécution
```bash
./assign1 < test.txt
./assign2 < test.txt
```

---


## Partie 1: Grammaire codant les priorité d'opérateurs


### Grammaire formelle

Voici la grammaire non ambiguë implémentée :

```
S  → L
L  → A ; L | ε
A  → VAR = A | M
M  → T M'
M' → + T M' | - T M' | [ M ] M' | ε
T  → P T'
T' → * P T' | / P T' | ε
P  → F P'
P' → ^ P | ε
F  → VAR | ENTIER | ( A )
```
### Traduction en Bison

Pour traduire cette grammaire en Bison, nous éliminons les non-terminaux avec prime (`M'`, `T'`, `P'`) en utilisant la **récursion gauche** (plus efficace pour les parsers LR) :

```
S → L
L → ε | A ; L
A → VAR = A | M
M → T | M + T | M - T | M [ M ]
T → P | T * P | T / P
P → F | F ^ P
F → ENTIER | VAR | ( A )
```

**Points importants :**

1. **Récursion gauche** pour `M` et `T` : 
   - `M → M + T` au lieu de `M → T + M`
   - Donne l'associativité gauche pour `+`, `-`, `*`, `/`

2. **Récursion droite** pour `P` : 
   - `P → F ^ P` 
   - Donne l'associativité droite pour `^`

3. **Récursion droite** pour `A` : 
   - `A → VAR = A` 
   - Permet les assignations chaînées `x = y = 5`

4. **`M [ M ]`** : 
   - Permet les crochets imbriqués comme `3[4*5[4]+1]`

---

### Justification de la grammaire

#### 1. Opérateur modulo `[n]` - Priorité la plus faible

L'opérateur `[n]` est dans `M`, le niveau le plus haut, donc il a la priorité **la plus faible** (inférieure aux opérateurs additifs).

**Exemple :** `5 + 3[4]`

```
Arbre syntaxique :
    M
   / \
  M  [M]
 / \   |
M + T  4
|   |
T   3
|
5

Interprétation : (5 + 3)[4] = 8[4] = 8 mod 4 = 0
```
#### 2. Associativité droite de `^`

La récursion **droite** de `P → F ^ P` donne l'associativité droite.

**Exemple :** `2 ^ 3 ^ 2`

```
Arbre syntaxique :
    P
   / \
  F ^ P
  |  / \
  2 F ^ P
    |   |
    3   2

Interprétation : 2 ^ (3 ^ 2) = 2 ^ 9 = 512
```
#### 3. Crochets imbriqués

`M → M [ M ]` permet les expressions complexes avec crochets imbriqués.

**Exemple :** `3[4*5[4]+1]`

```
Calcul étape par étape :
1. Évalue 5[4] → 5 mod 4 = 1
2. Calcule 4*1 = 4
3. Calcule 4+1 = 5
4. Évalue 3[5] → 3 mod 5 = 3

Résultat : 3
```

---

---

### Compilation sans conflits

Avec cette grammaire **non ambiguë**, Bison ne détecte **aucun conflit** :

```bash
make
bison assign1.y --defines=assign1.h -o assign1.c -r all

```
**Résultat :** Aucun message d'erreur ou de warning = **0 conflits**
**Ceci confirme que la grammaire est non ambiguë.**

---

### Limitations connues

- **Opérateurs unaires** : Non supportés dans cette version
  - ❌ `a = -2;` → erreur de syntaxe
  - ✅ `a = 0 - 2;` → fonctionne correctement
  - **Justification** : Le sujet demande uniquement les opérateurs **binaires**
  
- **Variables non initialisées** : Valent `0` par défaut

- **Division par zéro** : Détectée avec message d'erreur, retourne `0`

---

## Tests effectués : 
Tous les testes passent sur caseine.

--- 
## Conclusion de la Partie 1

La Partie 1 est avec une grammaire **non ambiguë** qui encode directement les priorités d'opérateurs dans sa structure hiérarchique. 

**Points clés :**
- Bison ne détecte **aucun conflit**, confirmant la correction de la grammaire
- L'arbre syntaxique reflète fidèlement les priorités et associativités
- Tous les tests du sujet passent avec succès
- Support des expressions complexes avec crochets imbriqués


## Partie 2: Grammaire ambiguë 
Utiliser une **grammaire ambiguë simplifiée** pour les expressions, puis résoudre automatiquement les conflits générés en déclarant les **priorités et associativités** des opérateurs via les directives Bison (`%left`, `%right`).

## Grammaire ambiguë

### Grammaire formelle

Voici la grammaire **ambiguë** implémentée dans `assign2.y` :

```
Source → List
List → ε | List Assign ;
Assign → VAR = Assign | Expr
Expr → Expr + Expr
     | Expr - Expr
     | Expr * Expr
     | Expr / Expr
     | Expr ^ Expr
     | Expr [ Expr ]
     | ( Assign )
     | - Expr
     | ENTIER
     | VAR
```

### Pourquoi cette grammaire est ambiguë

Cette grammaire est **ambiguë** car une expression comme `2 + 3 * 4` peut être analysée de **deux façons différentes** :

**Arbre 1 : Addition d'abord**
```
    Expr
   /  |  \
Expr + Expr
  |    /  |  \
  2  Expr * Expr
       |     |
       3     4

Résultat : (2 + 3) * 4 = 20  ❌ INCORRECT
```
**Arbre 2 : Multiplication d'abord**
```
    Expr
   /  |  \
Expr + Expr
  |    /  |  \
  2  Expr * Expr
       |     |
       3     4

Résultat : 2 + (3 * 4) = 14  ✅ CORRECT
```

Sans directives de priorité, Bison ne sait pas quelle interprétation choisir → **conflit shift/reduce**.

---

## Résolution des conflits par directives

### Déclaration des priorités dans assign2.y

Les priorités sont déclarées dans l'**ordre croissant** (du plus faible au plus fort) :

```c
/* Priorités (première = plus faible) */
%left LBRACK              /* Priorité 1 : Modulo [n] */
%left PLUS MINUS          /* Priorité 2 : Addition, soustraction */
%left MULT DIV            /* Priorité 3 : Multiplication, division */
%right EXPON              /* Priorité 4 : Puissance ^ */
%right UMINUS             /* Priorité 5 : Moins unaire */
```

**Règles importantes :**

1. **Ordre = priorité croissante** : La première directive a la priorité la plus **faible**, la dernière la plus **forte**

2. **`%left`** : Associativité **gauche**
   - `10 - 5 - 3` = `(10 - 5) - 3` = `2`

3. **`%right`** : Associativité **droite**
   - `2 ^ 3 ^ 2` = `2 ^ (3 ^ 2)` = `512`

4. **`%prec UMINUS`** : Pour le moins unaire, on utilise une pseudo-priorité
   - `-2 ^ 3` = `-(2 ^ 3)` = `-8`

## Analyse des conflits

### Compilation avec détection des conflits

```bash
$ bison assign2.y --defines=assign2.h -o assign2.c -r all
```

L'option `-r all` génère le fichier **`assign2.output`** qui contient :
- L'automate LR avec tous ses états
- Les conflits détectés
- Comment chaque conflit a été résolu

### Vérification des résolutions

```bash
$ grep -i "conflict" assign2.output
```

**Exemple de sortie :**

```
Conflict between rule 6 and token LBRACK resolved as reduce (LBRACK < PLUS).
Conflict between rule 6 and token PLUS resolved as reduce (%left PLUS).
Conflict between rule 6 and token MINUS resolved as reduce (%left MINUS).
Conflict between rule 6 and token MULT resolved as shift (PLUS < MULT).
Conflict between rule 6 and token DIV resolved as shift (PLUS < DIV).
Conflict between rule 6 and token EXPON resolved as shift (PLUS < EXPON).
...
Conflict between rule 10 and token EXPON resolved as shift (%right EXPON).
```
**Interprétation :**
- **`resolved as reduce`** : L'opérateur à gauche est **plus prioritaire** ou de **même priorité** (associativité gauche)
- **`resolved as shift`** : L'opérateur à droite est **plus prioritaire**

### Exemples de résolutions
#### Conflit 4 : Modulo plus faible que addition

```
Conflict between rule 6 and token LBRACK resolved as reduce (LBRACK < PLUS)
```

**Signification :** `[n]` a une priorité plus **faible** que `+`

**Résultat :** `5 + 3[4]` = `(5 + 3)[4]` = `0` 

---

## Conclusion de la Partie 2

La Partie 2 démontre l'efficacité des **directives de priorité de Bison** pour simplifier la grammaire :

**Points clés :**
-  Grammaire **plus simple** et **plus lisible** que la Partie 1
-  **Tous les conflits résolus** automatiquement par Bison
- Résultats **identiques** à la Partie 1
- Support du **moins unaire** en bonus
- Fichier `.output` permet de **vérifier** les résolutions

**Apprentissages :**
- Comprendre la différence entre grammaire ambiguë et non ambiguë
- Maîtriser les directives `%left`, `%right`, `%prec` de Bison
- Analyser les conflits shift/reduce et leurs résolutions
- Voir comment Bison construit son automate LR

---
