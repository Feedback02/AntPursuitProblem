using Javis,Animations,Colors
using Interpolations
nframes = 800
velocity = 1
n_ants = 2
interval_between_ants = 20.0 #in secondi
lengthPaths = Float64[0.0 for _ in 1:n_ants] #lunghezza in metri del path della formica i

stopAnts = false #se true, allora abbiamo raggiunto il cammino minimo
radius_ant = 3 #grandezza formica

vertices_square = [Point(-200.0,-200.0), Point(190.0,190.0)]
obstacle_square = [Point(-100.0,-100.0), Point(50.0,50)]
lengthOptimalPath = sqrt((vertices_square[1].y-vertices_square[2].y)^2 + (vertices_square[1].x-vertices_square[2].x)^2)
convergeToOptimalAt = 0 #secondi
ant_left_side = vertices_square[1] - radius_ant
ant_rigth_side = vertices_square[1] +radius_ant
ant_antenna = [vertices_square[1]+Point(3*radius_ant,radius_ant), Point(2*radius_ant,0)
                    ,vertices_square[1]+Point(3*radius_ant,-radius_ant)]
#grafica

#muovi title nel punto 0,-200 quando stopants = true .

function title(args...)
    fontsize(20)
    text("Thesis Title", Point(0, -230),
        valign=:middle, halign=:center)
end
function ground(args...)
    background("darkturquoise")
    sethue("black")
end

function object(p=O, color="black")
    sethue(color)
    circle(p, 0.05, :fill)
    return p
end
function connector(p1::Point, p2::Point, color::String)
    sethue(color)
    line(p1,p2, :stroke)
end

function message(i::Int64, video, action, frame)
if(!stopAnts)
    global convergeToOptimalAt = frame
    global stopAnts = true
    #println("$lengthPaths")
end

    fontsize(15)
    text("Optimal path length $(round(lengthOptimalPath;digits=2))m in $(round(convergeToOptimalAt/30;digits=2))s ant n = $i", 
    Point(-20, -210),valign=:middle, halign=:center)
end



function path!(points::Vector{Point}, pos::Point, color::RGB,i::Int64)

    if(points != [] && pos.x>(vertices_square[2].x-1) && pos.y >(vertices_square[2].y-1))
        if( !stopAnts &&  isapprox(lengthPaths[i],lengthOptimalPath,atol=0.5))
        #println("qpoweir")
            Object(1:nframes,(args...)->message(i,args...))
        end
        empty!(points)
    else
        sethue(color.r,color.g,color.b)
        push!(points, pos) # add pos to points
        circle.(points, 0.5, :fill) # draws a circle for each point using broadcasting
    end
    #println("lol - $lol")
end

function graphicFood(
    p = O,
    fill_color = "pink",
    outline_color = "black",
    action = :fill,
    radius = 5,
    circ_text = "",
 )
    sethue(fill_color)
    Javis.circle(p, radius, :fill)
    sethue(outline_color)
    Javis.circle(p, radius, :stroke)
    Javis.text(circ_text, p, valign = :middle, halign = :center)
end




#fine parte grafica








#calcoli
function getPointAfterCollisionDetec(ant::Object,p1::Point,i::Int64,sidePos::Point)
    #lato sinistro del quadrato
    if(sidePos.x !== 0)
        #if(p1.)
       # println(sidePos)
        p2 = Point(sidePos.x, p1.y+velocity)
        #return calcNewPoint(ant,p,p2,i)
        return p2
    end
    return 0
end

function collisionDetection(pos::Point)
    #quale lato la formica ha toccato?
 if( ( (pos.y >= obstacle_square[1].y && pos.y <= obstacle_square[2].y)))
    if(isapprox(pos.x,obstacle_square[1].x,atol=2))
    #if(pos.x >= obstacle_square[1].x)
        #the costant point of pos ant will be this
        println("lol")
        return Point(obstacle_square[1].x,0)
    elseif(isapprox(pos.x,obstacle_square[2].x,atol=2))
        return Point(obstacle_square[2].x,0)
    end
end
 if ( (pos.x >= obstacle_square[1].x && pos.x <= obstacle_square[2].x) ) 
    if(isapprox(pos.y ,obstacle_square[1].y,atol=2))
        #the costant point of pos ant will be this
        return Point(0,obstacle_square[1].y)
    elseif(isapprox(pos.y,obstacle_square[2].y,atol=2))
        return Point(0,obstacle_square[2].y)
    end
end
    return Point(NaN,NaN)
end



function getNextPoint(ant::Object, antchased=O,typeAnt = "follower",cubic_spline = 0,i = 1)


        if(typeAnt == "follower")
         return (args...) ->getPointFollower(ant, antchased,i)
        elseif (typeAnt == "pioneer")
         return (args...) ->getPointPioneer(ant, cubic_spline,i)
        end

    end
   

function getPointFollower(ant::Object, antchased::Object,i::Int64)
    #if(i>=n_ants-1) println("$lengthPaths") 
    #end
    p1 = pos(ant)
    pointDetection = collisionDetection(p1)
    if(pointDetection === Point(NaN,NaN) )
        p2 = pos(antchased)
    else
        println(pointDetection)
        p2 = getPointAfterCollisionDetec(ant,p1,i,pointDetection)
    end

        if(lengthPaths[i-1] >= interval_between_ants)
            new_point = calcNewPoint(ant,p1,p2,i)
            ant.change_keywords[:center] = new_point
    end



end

function getPointPioneer(ant::Object, cubic_spline, i::Int64)

    p1 = pos(ant)
    p2 = Point(p1.x + 1,cubic_spline(p1.x + 1))
    new_point = calcNewPoint(ant,p1,p2,i)
    ant.change_keywords[:center] = new_point


end





#j=0

function calcNewPoint(ant::Object,p1::Point,p2::Point,i::Int64)::Point

    if(!(p1.x >= (vertices_square[2].x) && p1.y >= (vertices_square[2].y)))
       # println(collisionDetection(p1))
    distance = p2-p1
    #normalizziamo
    distanceVectorNormalized = distance/sqrt(distance.x^2 + distance.y^2)
    distanceCovered = distanceVectorNormalized*velocity
    new_point = p1 + distanceCovered
    lengthPaths[i] = lengthPaths[i]+sqrt((p1.y - new_point.y)^2 +(p1.x - new_point.x)^2)
   # global  j=j+1
   #println("x $(abs(distanceCovered.x)) y $(abs(distanceCovered.y)) $j $new_point $p1")
   # serve per la parte grafica
   ant.opts[:distanceVectorNormalized] = distanceVectorNormalized
    return new_point
    end
    return vertices_square[2]
end

function getCurveAntPioneer()
    x = LinRange(-200,190,11)
    return  CubicSplineInterpolation(x, [-190,-100,-50,-80,-10,30,75,54,108,35,190], 
                                                extrapolation_bc = Interpolations.Line())
end


#x_ext = LinRange(0,190,100)




myvideo = Video(500, 500)
Background(1:nframes, ground)
Object(title)
#la curva della formica pioniere
cubic_spline = getCurveAntPioneer()

# Box
Object(JBox(vertices_square[1], vertices_square[2], color = "black", action = :stroke))
Object(JBox(obstacle_square[1], obstacle_square[2], color = "green", action = :stroke))


food = Object(1:nframes, (args...)->graphicFood(vertices_square[2]) )
Anthill = Object(1:nframes, (args...)->graphicFood(vertices_square[1],"green") )

#retta blu per avere un riferimento grafico
Object((args...) -> connector(vertices_square[1],vertices_square[2], "blue"))

ants = Object[]
path_ants = Vector[Point[] for _ in 1:n_ants]


colors_ants = colormap("Oranges", 200; mid=5, logscale=false)
colors_ants_paths = colormap("Purples", 200; mid=5, logscale=false)

for i in 1:n_ants
    
    push!(ants,Object(1:nframes,(args...;
                            center = vertices_square[1]) -> begin

    new_vec_orientation_ant = ants[i].opts[:distanceVectorNormalized] * radius_ant

    color = "black"
     sethue(colors_ants[201-i].r, colors_ants[201-i].g, colors_ants[201-i].b)
    #teniamo in considerazione l'angolazione.
    #θ = atand((vel_vector.y - vec_orientation_ant.y)/(vel_vector.x - vec_orientation_ant.x))
    #new_vec_orientation_ant = Point( (cos(θ) * radius_ant), (sin(θ) * radius_ant))
   

    testa = Point(new_vec_orientation_ant.x + center.x, new_vec_orientation_ant.y + center.y )
    coda = Point(-new_vec_orientation_ant.x + center.x,  -new_vec_orientation_ant.y+ center.y )



    circle.([testa,coda], radius_ant, :fill)
   # setcolor("black")
    


    do_action(:stroke)
    return center
                                              end ))
                                              
                                              
                                              
                                              ants[i].opts[:distanceVectorNormalized] = Point(0,0)
                                              
                                              
end






#formica pioniere
Object(1:nframes, (args...)->path!(path_ants[1], pos(ants[1]),colors_ants_paths[1],1))
act!(ants[1], Action(
    2:nframes,
    getNextPoint(ants[1],        0,"pioneer",cubic_spline),
    
))

for i in 2:n_ants
    Object(1:nframes, (args...)->path!(path_ants[i], pos(ants[i]), colors_ants_paths[i],i))
    act!(ants[i], Action(2:nframes, getNextPoint(ants[i],ants[i-1],"follower",0,i)))
end

#println(Javis.CURRENT_VIDEO[1].background_nframes)




render(myvideo; pathname = "shorthand_examples.gif")