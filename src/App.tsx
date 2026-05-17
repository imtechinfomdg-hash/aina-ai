import React, { useState, useEffect, useRef } from 'react';
import { Bell, Droplet, Moon, Baby, LineChart, Clock, ChevronRight, Home, Calendar, Shield, User, ChevronDown, MoreVertical, ChevronLeft, Droplets, Stethoscope, MessageCircle, Send, Mic, Camera } from 'lucide-react';
import { LineChart as RechartsLineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import babyBg from '../assets/images/baby_background.png';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState('home');

  if (currentScreen === 'dashboard') {
    return <DashboardScreen onBack={() => setCurrentScreen('home')} />;
  }

  if (currentScreen === 'chat') {
    return <ChatScreen onBack={() => setCurrentScreen('home')} />;
  }

  if (currentScreen === 'growth') {
    return <GrowthChartScreen onBack={() => setCurrentScreen('home')} />;
  }

  return <HomeScreen onNavigate={(screen) => setCurrentScreen(screen)} />;
}

function HomeScreen({ onNavigate }) {
  // ...
  return (
    <div className="min-h-screen bg-[#E5ECEF] pb-24 font-sans relative">
      {/* Top Profile */}
      <div className="px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-full bg-gray-300 overflow-hidden flex items-center justify-center">
            <Baby className="w-8 h-8 text-white" />
          </div>
          <div>
            <h1 className="font-bold text-lg text-gray-900">Hello, Mom 👶💛</h1>
            <p className="text-gray-500 text-sm">Baby is doing great today</p>
          </div>
        </div>
        <button className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm">
          <Bell className="w-5 h-5 text-gray-800" />
        </button>
      </div>

      {/* Status Card */}
      <div className="mx-6 my-4 p-5 bg-[#174266] rounded-3xl relative overflow-hidden flex shadow-lg" style={{ backgroundImage: `url(${babyBg})`, backgroundSize: 'cover', backgroundPosition: 'right' }}>
        <div className="absolute inset-0 bg-[#174266]/80"></div>
        <div className="flex-1 w-3/5 z-10 relative">
          <div className="inline-block px-3 py-1 bg-white/10 rounded-full mb-3">
            <span className="text-white/70 text-[10px] font-bold uppercase tracking-wider">Baby Status</span>
          </div>
          <h2 className="text-white text-xl font-bold mb-1">Happy & Active 😊</h2>
          <p className="text-white/70 text-xs mb-4">Last fed 1 hour ago</p>
          <button 
            onClick={() => onNavigate('dashboard')}
            className="bg-[#00C4B5] text-white text-xs font-bold px-4 py-2 rounded-full hover:bg-[#00a396] transition-colors"
          >
            Add Activity
          </button>
        </div>
        <div className="absolute right-0 top-0 bottom-0 w-1/2 opacity-20">
          <div className="w-full h-full bg-blue-300 rounded-full blur-2xl transform translate-x-1/2"></div>
        </div>
      </div>

      {/* Grid Icons */}
      <div className="px-6 flex justify-between gap-3">
        <IconItem icon={Droplet} label="Feed" color="text-blue-500" />
        <IconItem icon={Moon} label="Sleep" color="text-indigo-500" />
        <IconItem icon={Baby} label="Diaper" color="text-purple-500" />
        <IconItem icon={LineChart} label="Growth" color="text-[#00C4B5]" onClick={() => onNavigate('growth')} />
      </div>

      {/* Filter Chips */}
      <div className="px-6 py-6 flex gap-2 overflow-x-auto no-scrollbar">
        <Chip label="Routine" isSelected />
        <Chip label="First Aid" icon={Stethoscope} />
        <div onClick={() => onNavigate('chat')}>
          <Chip label="Baby Assistant" icon={MessageCircle} />
        </div>
      </div>

      {/* Nap Card */}
      <div className="mx-6 h-48 rounded-3xl overflow-hidden relative shadow-lg">
        <div className="absolute inset-0 bg-blue-100 flex items-center justify-center">
            <img src={babyBg} className="w-full h-full object-cover" alt="Baby Background" />
        </div>
        <div className="absolute inset-0 bg-gradient-to-b from-black/40 via-transparent to-black/70 p-5 flex flex-col justify-between">
          <div className="flex justify-between items-start">
            <div>
              <h3 className="text-white font-bold text-lg shadow-sm">Morning Nap 😴</h3>
              <p className="text-white/90 text-sm drop-shadow-md">Slept for 30 minutes</p>
            </div>
            <div className="bg-white/20 backdrop-blur-md px-3 py-1.5 rounded-full flex items-center gap-1">
              <Clock className="w-3 h-3 text-white" />
              <span className="text-white text-xs font-bold">11:00 AM</span>
            </div>
          </div>
          <div className="flex justify-between items-center group cursor-pointer" onClick={() => onNavigate('dashboard')}>
            <span className="text-white font-semibold text-sm group-hover:underline">Start Tracking</span>
            <div className="w-8 h-8 bg-white rounded-full flex items-center justify-center transition-transform group-hover:scale-105">
              <ChevronRight className="w-4 h-4 text-black" />
            </div>
          </div>
        </div>
      </div>

      {/* Floating Nav Bar */}
      <div className="fixed bottom-6 left-8 right-8 h-16 bg-white rounded-[32px] shadow-[0_10px_30px_rgba(0,0,0,0.1)] flex justify-evenly items-center z-50">
        <NavItem icon={Home} isSelected />
        <NavItem icon={Calendar} />
        <NavItem icon={Shield} />
        <NavItem icon={User} />
      </div>
    </div>
  );
}

function ChatScreen({ onBack }) {
  const [messages, setMessages] = useState([
    { id: 1, text: "Salama! Izaho no Aina. Inona no mety hanampiako anao momba ny fahasalaman'ny zanakao?", isUser: false }
  ]);
  const [inputText, setInputText] = useState("");
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = () => {
    if (!inputText.trim()) return;
    
    // Add user message
    const userMsg = { id: Date.now(), text: inputText, isUser: true };
    setMessages(prev => [...prev, userMsg]);
    setInputText("");

    // Simulate AI response
    setTimeout(() => {
      setMessages(prev => [...prev, {
        id: Date.now(),
        text: "Misaotra amin'ny fanontanianao. Amin'ny maha mpanampy ahy dia afaka manoro hevitra anao aho momba ny filan'ny zanakao na dia tsy dokotera aza aho. Inona ny hita amin'ny zaza?",
        isUser: false
      }]);
    }, 1000);
  };

  return (
    <div className="min-h-screen bg-[#F0F4F8] font-sans flex flex-col">
      {/* Top App Bar */}
      <div className="flex justify-between items-center px-4 py-4 bg-white shadow-sm z-10 sticky top-0">
        <button onClick={onBack} className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center hover:bg-gray-200 transition-colors">
          <ChevronLeft className="w-5 h-5 text-gray-800" />
        </button>
        <div className="flex flex-col items-center">
          <h1 className="font-bold text-base text-gray-900">Aina Assistant IA</h1>
          <span className="text-[10px] font-medium text-green-600 bg-green-50 px-2 py-0.5 rounded-full mt-0.5">En Ligne (Local)</span>
        </div>
        <button className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center hover:bg-gray-200 transition-colors">
          <MoreVertical className="w-5 h-5 text-gray-800" />
        </button>
      </div>

      {/* Warning Banner */}
      <div className="bg-amber-50 px-4 py-2 flex items-start gap-2 border-b border-amber-100">
        <Shield className="w-4 h-4 text-amber-500 mt-0.5 flex-shrink-0" />
        <p className="text-[10px] text-amber-700 leading-tight">
          Aina dia mpanampy ara-pahasalamana C-IMCI. Raha misy vonjy taitra, mitadiava dokotera avy hatrany.
        </p>
      </div>

      {/* Chat Area */}
      <div className="flex-1 overflow-y-auto px-4 py-6 flex flex-col gap-4">
        {messages.map((msg) => (
          <div key={msg.id} className={`flex ${msg.isUser ? 'justify-end' : 'justify-start'}`}>
            {!msg.isUser && (
              <div className="w-8 h-8 rounded-full bg-teal-100 flex items-center justify-center mr-2 flex-shrink-0">
                <Baby className="w-5 h-5 text-teal-600" />
              </div>
            )}
            <div 
              className={`max-w-[75%] rounded-2xl px-4 py-2.5 text-sm shadow-sm ${
                msg.isUser 
                  ? 'bg-[#00C4B5] text-white rounded-br-sm' 
                  : 'bg-white text-gray-800 rounded-bl-sm border border-gray-100'
              }`}
            >
              {msg.text}
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Area */}
      <div className="bg-white p-4 shadow-[0_-5px_15px_rgba(0,0,0,0.05)] sticky bottom-0">
        <div className="flex items-end gap-2">
          <button className="p-2.5 text-gray-400 hover:bg-gray-100 rounded-full transition-colors flex-shrink-0">
            <Camera className="w-5 h-5" />
          </button>
          
          <div className="flex-1 bg-gray-100 rounded-2xl flex items-center px-4 py-1 min-h-[44px]">
            <input 
              type="text" 
              placeholder="Saisissez votre message..."
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSend()}
              className="w-full bg-transparent border-none outline-none text-sm text-gray-800 py-2"
            />
          </div>

          {inputText.trim() ? (
            <button 
              onClick={handleSend}
              className="p-3 bg-[#00C4B5] text-white rounded-full hover:bg-teal-500 transition-colors shadow-sm flex-shrink-0"
            >
              <Send className="w-4 h-4 ml-0.5" />
            </button>
          ) : (
            <button className="p-3 bg-gray-100 text-gray-500 rounded-full hover:bg-gray-200 transition-colors flex-shrink-0">
              <Mic className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function DashboardScreen({ onBack }) {
  const [selectedPeriod, setSelectedPeriod] = useState('Day');

  return (
    <div className="min-h-screen bg-[#E5ECEF] font-sans pb-10">
      {/* Top App Bar */}
      <div className="flex justify-between items-center px-4 py-3 bg-[#E5ECEF]">
        <button onClick={onBack} className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm">
          <ChevronLeft className="w-5 h-5 text-gray-800" />
        </button>
        <h1 className="font-bold text-base text-gray-900">Activity Tracker</h1>
        <button className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm">
          <MoreVertical className="w-5 h-5 text-gray-800" />
        </button>
      </div>

      {/* Period Tabs */}
      <div className="mx-6 my-4 p-1 bg-white rounded-full flex justify-between shadow-sm">
        {['Day', 'Week', 'Month', 'Year'].map(period => (
          <button
            key={period}
            onClick={() => setSelectedPeriod(period)}
            className={`flex-1 text-center py-2.5 rounded-full text-sm transition-colors ${
              selectedPeriod === period 
                ? 'bg-[#00C4B5] text-white font-bold' 
                : 'bg-transparent text-gray-500 font-medium hover:text-gray-900'
            }`}
          >
            {period}
          </button>
        ))}
      </div>

      {/* Overview Card */}
      <div className="mx-6 p-6 bg-white rounded-3xl shadow-sm">
        <div className="flex justify-between items-center mb-8">
          <h2 className="font-bold text-sm text-gray-900">Daily Activity Overview</h2>
          <div className="border border-gray-200 rounded-xl px-2.5 py-1 flex items-center gap-1 cursor-pointer hover:bg-gray-50">
            <span className="text-xs text-gray-600">Today</span>
            <ChevronDown className="w-4 h-4 text-gray-600" />
          </div>
        </div>

        {/* Chart Area */}
        <div className="relative w-40 h-40 mx-auto mb-8 flex items-center justify-center">
            {/* Fake Circular Progress */}
           <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
             <circle cx="50" cy="50" r="40" fill="transparent" stroke="#00C4B5" strokeWidth="12" strokeOpacity="0.3" />
             <circle cx="50" cy="50" r="40" fill="transparent" stroke="#2563EB" strokeWidth="12" strokeDasharray="251.2" strokeDashoffset="75.36" strokeLinecap="round" />
           </svg>
          <div className="absolute flex flex-col items-center">
            <span className="text-[10px] text-gray-400 font-medium">Total Activities</span>
            <span className="text-sm font-bold text-gray-900">12 Logs Today</span>
          </div>
        </div>

        {/* Legends */}
        <div className="flex flex-wrap justify-center gap-2">
          <LegendItem color="bg-blue-600" label="Feeding (4)" />
          <LegendItem color="bg-indigo-500" label="Sleep (3)" />
          <LegendItem color="bg-[#00C4B5]" label="Diaper (3)" />
          <LegendItem color="bg-teal-200" label="Bath (1)" />
          <LegendItem color="bg-blue-100" label="Playtime (1)" />
        </div>
      </div>

      {/* Bars Card */}
      <div className="mx-6 my-4 p-6 bg-white rounded-3xl shadow-sm">
        <h2 className="font-bold text-sm text-gray-900 mb-6">Today's Baby Care Overview</h2>
        
        <div className="space-y-4">
          <BarItem label="Feeding" pct={85} color="bg-[#00C4B5]" />
          <BarItem label="Sleep" pct={70} color="bg-indigo-300" />
          <BarItem label="Diaper" pct={65} color="bg-blue-300" />
          <BarItem label="Hydration" pct={45} color="bg-amber-300" />
        </div>
      </div>
    </div>
  );
}

// Subcomponents

function IconItem({ icon: Icon, label, color, onClick }) {
  return (
    <div className="flex flex-col items-center gap-2 cursor-pointer w-1/4" onClick={onClick}>
      <div className="bg-white w-full aspect-square rounded-2xl shadow-sm flex items-center justify-center hover:shadow-md transition-shadow">
        <Icon className={`w-7 h-7 ${color}`} />
      </div>
      <span className="text-xs font-medium text-gray-800">{label}</span>
    </div>
  );
}

function Chip({ label, isSelected, icon: Icon }) {
  return (
    <div className={`
      flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-2xl whitespace-nowrap cursor-pointer transition-colors
      ${isSelected ? 'bg-[#00C4B5] text-white shadow-md' : 'bg-white text-gray-500 border border-gray-100 shadow-sm hover:border-gray-200'}
    `}>
      {Icon && <Icon className="w-4 h-4" />}
      <span className={`text-[13px] ${isSelected ? 'font-bold' : 'font-medium'}`}>{label}</span>
    </div>
  );
}

function NavItem({ icon: Icon, isSelected }) {
  return (
    <div className={`p-3 rounded-full cursor-pointer transition-colors ${isSelected ? 'bg-black' : 'hover:bg-gray-100'}`}>
      <Icon className={`w-6 h-6 ${isSelected ? 'text-white' : 'text-gray-400'}`} />
    </div>
  );
}

function LegendItem({ color, label }) {
  return (
    <div className="flex items-center gap-1.5 px-2 py-1 bg-white border border-gray-100 rounded-md">
      <div className={`w-2 h-2 rounded-sm ${color}`}></div>
      <span className="text-[10px] text-gray-600 font-medium">{label}</span>
    </div>
  );
}

function BarItem({ label, pct, color }) {
  return (
    <div className="flex items-center h-5">
      <span className="w-[70px] text-[13px] text-gray-600">{label}</span>
      <div className="flex-1 h-full bg-gray-100 rounded flex">
        <div 
          className={`h-full ${color} rounded-l pr-2 flex items-center justify-end`}
          style={{ width: `${pct}%` }}
        >
          <span className="text-[10px] font-bold text-white leading-none">{pct}%</span>
        </div>
      </div>
    </div>
  );
}

function GrowthChartScreen({ onBack }) {
  const data = [
    { month: 'M0', weight: 3.2, height: 50 },
    { month: 'M1', weight: 4.2, height: 54 },
    { month: 'M2', weight: 5.1, height: 58 },
    { month: 'M3', weight: 5.8, height: 61 },
    { month: 'M4', weight: 6.5, height: 63 },
    { month: 'M5', weight: 7.0, height: 65 },
    { month: 'M6', weight: 7.5, height: 67 },
  ];

  return (
    <div className="min-h-screen bg-[#E5ECEF] font-sans pb-10">
      {/* Top App Bar */}
      <div className="flex justify-between items-center px-4 py-4 bg-white shadow-sm z-10 sticky top-0">
        <button onClick={onBack} className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center hover:bg-gray-200 transition-colors">
          <ChevronLeft className="w-5 h-5 text-gray-800" />
        </button>
        <h1 className="font-bold text-base text-gray-900">Suivi Croissance</h1>
        <button className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center hover:bg-gray-200 transition-colors">
          <MoreVertical className="w-5 h-5 text-gray-800" />
        </button>
      </div>

      <div className="mx-6 my-6 p-6 bg-white rounded-3xl shadow-sm">
        <h2 className="font-bold text-sm text-gray-900 mb-6">Poids (kg)</h2>
        <div className="h-48 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <RechartsLineChart data={data}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} />
              <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6B7280'}} />
              <YAxis axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6B7280'}} />
              <Tooltip 
                contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
              />
              <Line type="monotone" dataKey="weight" stroke="#00C4B5" strokeWidth={3} dot={{r: 4, strokeWidth: 2}} activeDot={{r: 6}} />
            </RechartsLineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="mx-6 my-6 p-6 bg-white rounded-3xl shadow-sm">
        <h2 className="font-bold text-sm text-gray-900 mb-6">Taille (cm)</h2>
        <div className="h-48 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <RechartsLineChart data={data}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} />
              <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6B7280'}} />
              <YAxis domain={['dataMin - 2', 'dataMax + 2']} axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6B7280'}} />
              <Tooltip 
                contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
              />
              <Line type="monotone" dataKey="height" stroke="#8B5CF6" strokeWidth={3} dot={{r: 4, strokeWidth: 2}} activeDot={{r: 6}} />
            </RechartsLineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}

