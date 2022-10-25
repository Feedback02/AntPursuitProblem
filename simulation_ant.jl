using Javis,Animations
using Interpolations
nframes = 3000
velocity = 1
n_ants = 200
interval_between_ants = 25.0 #milliseconds
lengthPaths = Float64[0.0 for _ in 1:n_ants] #length path of ant i 

stopAnts = false #if true, it means we reached the minimum path


vertices_square = [Point(-200.0,-200.0), Point(190.0,190.0)]
lengthOptimalPath = sqrt((vertices_square[1].y-vertices_square[2].y)^2 + (vertices_square[1].x-vertices_square[2].x)^2)
convergeToOptimalAt = 0 #seconds

#grafica
radius_ant = 3 

function title(args...)
    fontsize(20)
    text("Il Problema Dell’inseguimento:Euristiche e Simulazioni", Point(0, -230),
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

function path!(points::Vector{Point}, pos::Point,i::Int64)

    if(points != [] && pos.x>(vertices_square[2].x-1) && pos.y >(vertices_square[2].y-1))
        if( !stopAnts &&  isapprox(lengthPaths[i],lengthOptimalPath,atol=0.5))
            Object(1:nframes,(args...)->message(i,args...))
        end
        empty!(points)
    else
        sethue("white")
        push!(points, pos) 
        circle.(points, 0.5, :fill) 
    end
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




#end graphics








#the ant pioneer is the first ant, the remaining one are followers

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
    if(lengthPaths[i-1] >= interval_between_ants)
    p2 = pos(antchased)
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
    distance = p2-p1
    #normalizziamo
    distanceVectorNormalized = distance/sqrt(distance.x^2 + distance.y^2)
    distanceCovered = distanceVectorNormalized*velocity
    new_point = p1 + distanceCovered
    lengthPaths[i] = lengthPaths[i]+sqrt((p1.y - new_point.y)^2 +(p1.x - new_point.x)^2)
   # global  j=j+1
   #println("x $(abs(distanceCovered.x)) y $(abs(distanceCovered.y)) $j $new_point $p1")
   # needed for graphics
   ant.opts[:distanceVectorNormalized] = distanceVectorNormalized
    return new_point
    end
    return vertices_square[2]
end

#the curve of the pioneer is generated by an polinomial interpolation
function getCurveAntPioneer()
    x = LinRange(-200,190,11)
    return  CubicSplineInterpolation(x, [-190,-100,-50,-80,-10,30,75,54,108,35,190], 
                                                extrapolation_bc = Interpolations.Line())
end


#x_ext = LinRange(0,190,100)




myvideo = Video(500, 500)
Background(1:nframes, ground)
Object(title)

cubic_spline = getCurveAntPioneer()

# Box
Object(JBox(vertices_square[1], vertices_square[2], color = "black", action = :stroke))
food = Object(1:nframes, (args...)->graphicFood(vertices_square[2]) )
Anthill = Object(1:nframes, (args...)->graphicFood(vertices_square[1],"green") )

#just to have some graphic reference
Object((args...) -> connector(vertices_square[1],vertices_square[2], "blue"))

ants = Object[]
path_ants = Vector[Point[] for _ in 1:n_ants]




for i in 1:n_ants
    
    push!(ants,Object(1:nframes,(args...;
                            center = vertices_square[1]) -> begin

    new_vec_orientation_ant = ants[i].opts[:distanceVectorNormalized] * radius_ant
    new_vec_orientation_ant1 = ants[i].opts[:distanceVectorNormalized] * 2 * radius_ant

     sethue("brown")
    

    head = Point(new_vec_orientation_ant.x + center.x, new_vec_orientation_ant.y + center.y )
    tail = Point(-new_vec_orientation_ant.x + center.x,  -new_vec_orientation_ant.y+ center.y )

    distanceVectorRigthAntenna = ants[i].opts[:antennaRigthPoint] - center
    distanceVectorLeftAntenna = ants[i].opts[:antennaLeftPoint] - center

    circle.([head,tail], radius_ant, :fill)
    
     ants[i].opts[:new_angolo] = atand((new_vec_orientation_ant.y - 1)/(new_vec_orientation_ant.x ))

     if((ants[i].opts[:old_angolo] - ants[i].opts[:new_angolo]) != 0)
        rad = ants[i].opts[:new_angolo] - ants[i].opts[:old_angolo]

        #println(rad)
        #println("$(ants[i].opts[:antennaLeftPoint]), $(ants[i].opts[:antennaCenterPoint]), $(ants[i].opts[:antennaRigthPoint])")
        #println("$(center),$(distanceVectorRigthAntenna), $(distanceVectorLeftAntenna)")
        #rotation matrix. TODO: the antenna are not perfect
        ants[i].opts[:antennaRigthPoint] = center + Point(-cosd(rad)*distanceVectorRigthAntenna.x  +sind(rad)*distanceVectorRigthAntenna.y,
                                                         -sind(rad)*distanceVectorRigthAntenna.x -cosd(rad)*distanceVectorRigthAntenna.y)
        ants[i].opts[:antennaCenterPoint] = center + new_vec_orientation_ant1
        ants[i].opts[:antennaLeftPoint] = center + Point(-cosd(rad)*distanceVectorLeftAntenna.x + sind(rad)*distanceVectorLeftAntenna.y,
                                                     -sind(rad)*distanceVectorLeftAntenna.x -cosd(rad)*distanceVectorLeftAntenna.y)


     end

    ants[i].opts[:old_angolo] = ants[i].opts[:new_angolo]
    curve(ants[i].opts[:antennaLeftPoint], ants[i].opts[:antennaCenterPoint], ants[i].opts[:antennaRigthPoint])

    do_action(:stroke)
    return center
                                              end ))

                                              ants[i].opts[:antennaRigthPoint] = vertices_square[1]+Point(5+radius_ant, radius_ant)
                                              ants[i].opts[:antennaCenterPoint] = vertices_square[1]+Point( (2*radius_ant)-2, 0)
                                              ants[i].opts[:antennaLeftPoint] = vertices_square[1]+Point(5+radius_ant, -radius_ant)
                                              ants[i].opts[:distanceVectorNormalized] = Point(0,0)
                                              ants[i].opts[:old_angolo] = 0
                                              ants[i].opts[:new_angolo] = 0                                            
end






#pioneer ant
Object(1:nframes, (args...)->path!(path_ants[1], pos(ants[1]),1))
act!(ants[1], Action(
    2:nframes,
    getNextPoint(ants[1],        0,"pioneer",cubic_spline),
    
))

for i in 2:n_ants
    Object(1:nframes, (args...)->path!(path_ants[i], pos(ants[i]),i))
    act!(ants[i], Action(2:nframes, getNextPoint(ants[i],ants[i-1],"follower",0,i)))
end

#println(Javis.CURRENT_VIDEO[1].background_nframes)



render(myvideo; pathname = "bruckstein_modello.mp4")
#render(myvideo; pathname = "bruckstein_modello.gif")
