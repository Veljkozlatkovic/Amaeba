#moja ideja je da uzmemo dva najbolja i da oni budu roditelji za naredno dete. Onaj koji je bio najbolji ostaje a ovaj drugi gine. ali sada imamo dete/cu od njih.Idalje ne znam koliko. A ove ostale 4-6 mogu da mutiram stalno i tako dobijam  stalno nov input za ove koje cuvam kako generacije prolaze.
extends Node2D

@export var Individuals:Array
@export var MainScene: PackedScene

func createRandom():
	var reflexMatrix=[		randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
							randf()-.5,randf()-.5,
	]
	return reflexMatrix


class Individual extends Object:
	func _init(genes,name):
		self.genes=genes
		self.name=name
	
	var name="";
	
	var genes=[]
	var representation:Area2D=null
	var score=-1
	var bestScore=0   #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11
	func getScore(score):
		self.score=score
		print(self.score)
		printerr("got score")
		if score>self.bestScore: #TODO BITNO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
			self.bestScore=score # ne mogu da ukapiram gde se "best score" cuva i kako da ga primenim.
		self.gotScore.emit(self)
	
	signal gotScore(individual:Individual)

func shallowCopy(ind):
	var new_Ind=Individual.new(ind.genes,ind.name+"I")
	new_Ind.bestScore=ind.bestScore
	return new_Ind;

func Ind_got_score(ind):
	var count=0
	for i in Individuals:
		if(i.score<0):
			count+=1
	if(count==0):
		printerr("done scoring")
		newGeneration()

var subViews=[]

func select(population):
	# ovde kucate kod koji obavlja proces selekcije.
	# treba da vratite podskup populacije
	# primer:
	# jedinke populacije su sortirane po uspesnosti
	# pa samo uzimamo uspesniju polovinu
	var chosen=[]
	#chosen.append(self.bestScore)# definitivno ne moze ovako
	#chosen.append()
	for i in range(int(len(population)/2)):
		chosen.append(population[i])  #!BITNO - u chosen mogu da stavljam samo preko population niza koliko vidim, nisam siguran.
	return chosen;
	
func cross(population):
	# ovde kucate kod koji obavlja proces ukrstanja
	# cilj je da se napravi nov objekat sa reflexMatrix
	# koji je napravljen od delova svojih "roditelja"
	# primer:
	var children=[]
	# polovina sledece populacije ce biti roditelji
	for p in population:
		children.append(p)
	#ukrstamo na dalje nasumicno 2 roditelja tako da dobijemo uvek
	# 2 deteta sa "suprotnim" osobinama oba roditelja
	# tako cemo ponovo dobiti isti broj jedinki za sledecu generaciju
	for parent1 in population:
		# izabrati 2 roditelja, prvi uzimamo redom, a drugog 
		# biramo nasumicno. Ovaj deo koda mozete da menjate 
		# odabir je na vama, ovo je samo primer
		var parent2=population[randi_range(0,len(population)-1)];
		#kopiranje matrice
		var child1=[]
		var child2=[]   #ovo se trenutno ne koristi, red 96 ako zelis da ga koristis
		
		for i in range(16):# broj elemenata matrice (gena)
			var odabir=randf() 	#bacamo novcic i biramo gen prvog 
								# ili drugog roditelja
			if(odabir<=0.5):
				child1.append(parent1.genes[i])
				child2.append(parent2.genes[i])
			else:
				child2.append(parent1.genes[i])
				child1.append(parent2.genes[i])
		children.append(Individual.new(child1,str(numberOfIndividuals)))
		#children.append(Individual.new(child2,str(numberOfIndividuals+1))) 
		numberOfIndividuals+=1
	return children

var numberOfIndividuals=0
func mutate(population):     # ovo vrv i ostavljam da bude random ali samo za najgora 4 ili 6(smislicu) 
	# ovde kucate kod koji obavlja proces mutacije.
	# izaberete jednu, ili mali broj jedinki,
	# i promenite joj nasumicno na neki nacin reflexMatrix
	var mutated=population[randi_range(0,len(population)-1)]
	mutated.genes[randi_range(0,16-1)]=randf()-0.5
	mutated.name=mutated.name+"M"
	return population;

func newGeneration():
	var population=[]
	
	Individuals.sort_custom(func(ind1,ind2) : return ind1.score>ind2.score)
	for i in Individuals:
		population.append(shallowCopy(i))
	population=mutate(cross(select(population)))   # !BITNO za znati zbog razumevanja ostatka...............
	reset(population);

func reset(population):
	#clear subviews
	for v in subViews:
		for n in v.get_children():
			v.remove_child(n)
			n.queue_free()
	Individuals=[]
	for i in range(len(subViews)):
		var ms=MainScene.instantiate()
		var ind=population[i]
		ind.representation=ms
		Individuals.append(ind)
		ind.gotScore.connect(Ind_got_score)
		ms.reflexMatrix=ind.genes
		
		ms.gameover.connect(ind.getScore)
		ms.NameLabel=ind.name
		ms.BestScore=ind.bestScore;
		subViews[i].add_child(ms)
	

func _ready():
	seed(43)
	var gridchildren=$GridContainer.get_children()
	#subViews=[$GridContainer/SubViewportContainer/SubViewport,$GridContainer/SubViewportContainer2/SubViewport
	#,$GridContainer/SubViewportContainer3/SubViewport,$GridContainer/SubViewportContainer4/SubViewport]
	#Individuals=[$SubViewportContainer/SubViewport/Main,$SubViewportContainer2/SubViewport/Main]
	subViews=[]
	for g in gridchildren:
		subViews.append(g.get_child(0))
	var population=[]
	var i=0
	for m in subViews:
		population.append(Individual.new(createRandom(),"{"+str(i)+"}"))
		i+=1
		numberOfIndividuals+=1
	reset(population);
	

func _process(delta):
	pass
