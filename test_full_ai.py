#\!/usr/bin/env python3
from nlp_frontend import NLPFrontend
from command_orchestrator import CommandOrchestrator

print('🤖 Linux AI Natural Language Shell Demo')
print('='*50)

# Initialize with correct model
nlp = NLPFrontend(model='llama3.2:1b')
orchestrator = CommandOrchestrator()

# Test natural language commands
test_commands = [
    'show me my current directory',
    'list all files in this folder',
    'check how much disk space I have',
    'find all Python files'
]

for user_input in test_commands:
    print(f'\n🗣️  User: "{user_input}"')
    
    # Process with NLP
    result = nlp.process_input(user_input)
    
    if result['type'] == 'command':
        command = result['command']
        print(f'🧠 Generated: {command}')
        
        # Execute command
        exec_result = orchestrator.execute_shell_command(command)
        
        if exec_result['success']:
            print('✅ Executed successfully')
            output = exec_result['output'].strip()
            if output:
                lines = output.split('\n')
                if len(lines) > 3:
                    print(f'📄 Output (first 3 lines):')
                    for line in lines[:3]:
                        print(f'   {line}')
                    print(f'   ... ({len(lines)-3} more lines)')
                else:
                    print(f'📄 Output: {output}')
        else:
            print(f'❌ Failed: {exec_result["error"]}')
    else:
        print(f'🔍 Result: {result}')
    
    print('-' * 40)

print('\n✅ Linux AI Demo Complete\!')
