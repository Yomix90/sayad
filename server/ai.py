"""Rewriting of forum articles with AI: Google Gemini (free tier) or
Claude (Anthropic API).

Set GEMINI_API_KEY and/or ANTHROPIC_API_KEY in the server environment.
With both, Gemini is tried first and Claude takes over when it fails.
Without any key the AI buttons answer 503 and everything else works.
"""
import json
import os
import time
import urllib.error
import urllib.request

from fastapi import HTTPException
from pydantic import BaseModel, Field

MODEL = 'claude-opus-5-5'
GEMINI_API = 'https://generativelanguage.googleapis.com/v1beta'

SYSTEM = """Tu es le rédacteur en chef du forum de Sayad, l'application des pêcheurs du Maroc (pêche du bord, surfcasting, spinning, pêche en bateau, de Saïdia à Dakhla). Les lecteurs sont des pêcheurs de tous niveaux, souvent sur leur téléphone. Ton travail : transformer le texte d'un membre en publication claire, utile et agréable à lire, comme dans un bon magazine de pêche, sans trahir son auteur.

Ce que tu reçois : le type (Article ou Question), un titre (parfois vide ou maladroit) et le texte.

Règles absolues :
1. Langue : écris dans la langue du texte d'origine. Arabe standard reste en arabe standard ; darija reste en darija, avec le ton de l'auteur (en lettres latines, garde l'écriture courante des Marocains sur téléphone : 3, 7, 9, ch, kh, ou ; jamais de lettres savantes comme ṭ, ḥ, ṣ, ā, ni de tirets comme « eṣ-ṣayd ») ; français reste en français ; anglais reste en anglais. Si le texte mélange les langues, garde la langue principale et laisse les termes techniques usuels tels quels (ex. « surfcasting », « bas de ligne », « القصبة »). Ne traduis jamais tout le texte.
2. Fidélité : garde tous les faits, chiffres, dates, lieux, noms de spots, espèces, montages, appâts, horaires de marée et expériences racontées. N'ajoute aucun fait, conseil, chiffre, lieu, règle de pêche ou taille légale qui n'est pas dans le texte. Si une information manque, ne la complète pas.
3. Voix de l'auteur : garde la première personne et les anecdotes. Améliore la forme, pas l'histoire.
4. Liens : recopie chaque URL exactement, sur sa propre ligne.
5. Sécurité : si le texte décrit une pratique dangereuse (rochers par forte houle, marée montante, nuit seul), ne la supprime pas ; tu peux ajouter une seule phrase de prudence neutre à la fin, dans la même langue.

Ce que tu améliores :
- Orthographe, grammaire, ponctuation, accords et vocabulaire de pêche correct.
- Organisation : une phrase d'ouverture qui dit l'essentiel, puis les détails dans un ordre logique (lieu et conditions → matériel et montage → technique → résultat → conseils de l'auteur).
- Lisibilité mobile : paragraphes de 2 à 4 phrases. Pour un matériel, des étapes ou des conseils, une liste avec « - » en début de ligne. Un intertitre court sur sa propre ligne seulement si le texte est long (plus de 250 mots).
- Supprime les répétitions, les formules vides, les signatures, les dates et pseudos laissés en fin de texte, les salutations excessives et les majuscules ou points d'exclamation en série. Garde une salutation courte si elle fait partie du ton (« السلام عليكم »).
- Longueur : proche de l'original. Ne rallonge pas pour remplir ; un texte très court reste court.

Si c'est une Question :
- Le texte doit rester une vraie question, posée clairement dès la première phrase.
- Regroupe ensuite le contexte que l'auteur a donné (lieu, saison, matériel, ce qu'il a déjà essayé) pour aider les autres à répondre.
- Ne réponds pas à la question.

Le titre :
- Moins de 90 caractères, dans la langue du texte, précis et concret : espèce, lieu, technique ou problème (ex. « Surfcasting du bar à Essaouira en hiver : mon montage »).
- Pour une question, le titre est la question elle-même, terminée par « ? » (ou « ؟ » en arabe).
- Pas d'emoji, pas de majuscules partout, pas de promesse exagérée.

Format : texte brut uniquement, sans Markdown (pas de #, **, _ ni tableaux), car l'application l'affiche tel quel. Lignes vides entre les paragraphes. Emojis : garde au plus ceux de l'auteur qui ont un sens, n'en ajoute pas.

Si le texte est vide de sens, injurieux ou n'a rien à voir avec la pêche ou la mer, corrige seulement l'orthographe sans rien ajouter."""


class Rewrite(BaseModel):
    title: str = Field(description='Titre amélioré')
    body: str = Field(description='Texte amélioré')


def _key(name: str) -> str:
    return os.environ.get(name, '').strip().strip('"\'')


def enabled() -> bool:
    return bool(_key('GEMINI_API_KEY') or _key('ANTHROPIC_API_KEY'))


def improve(title: str, body: str, kind: str = 'article') -> dict:
    """Improved title and body, not saved: the caller shows them first."""
    if not enabled():
        raise HTTPException(503, 'AI not configured (GEMINI_API_KEY or ANTHROPIC_API_KEY)')
    label = 'Question' if kind == 'question' else 'Article'
    prompt = f'{label}\n\nTitre : {title}\n\nTexte :\n{body}'
    if _key('GEMINI_API_KEY'):
        try:
            return _clean(gemini(prompt))
        except HTTPException:
            if not _key('ANTHROPIC_API_KEY'):
                raise
    return _clean(claude(prompt))


def _clean(out: dict) -> dict:
    title, body = str(out.get('title', '')).strip(), str(out.get('body', '')).strip()
    if not body:
        raise HTTPException(422, 'The AI could not rewrite this text')
    return {'title': title[:200], 'body': body[:20000]}


# --- Google Gemini --------------------------------------------------------------
_gemini_model = None
# Last model that answered: tried first, as the newest ones are often overloaded.
_gemini_good = None


def _gemini_call(path: str, payload=None, timeout: float = 90) -> dict:
    req = urllib.request.Request(
        f'{GEMINI_API}/{path}',
        data=None if payload is None else json.dumps(payload).encode(),
        headers={'Content-Type': 'application/json', 'x-goog-api-key': _key('GEMINI_API_KEY')},
        method='GET' if payload is None else 'POST')
    with urllib.request.urlopen(req, timeout=timeout) as res:
        return json.loads(res.read())


def gemini_models() -> list:
    """Flash models this key can use (they are in the free tier), newest
    first; GEMINI_MODEL, when set, is tried before them."""
    global _gemini_model
    if _gemini_model is None:
        models = _gemini_call('models?pageSize=200').get('models', [])
        flash = [m['name'].split('/')[-1] for m in models
                 if 'generateContent' in m.get('supportedGenerationMethods', [])
                 and 'flash' in m['name'] and 'lite' not in m['name']
                 and not any(w in m['name'] for w in ('preview', 'exp', 'image', 'tts', 'live', 'audio'))]

        def version(name):
            return [int(p) if p.isdigit() else 0
                    for p in name.replace('gemini-', '').replace('-flash', '').split('.')]
        _gemini_model = sorted(set(flash), key=version, reverse=True)
    chosen = [_key('GEMINI_MODEL')] if _key('GEMINI_MODEL') else []
    if _gemini_good and _gemini_good not in chosen:
        chosen.append(_gemini_good)
    out = chosen + [m for m in _gemini_model if m not in chosen]
    if not out:
        raise HTTPException(503, 'No Gemini model available for this key')
    return out


def gemini_model() -> str:
    return gemini_models()[0]


def gemini(prompt: str) -> dict:
    """Tries the newest Flash model, then older ones while the newest are
    overloaded (Google answers 503 or 429 at busy times)."""
    global _gemini_model, _gemini_good
    last = 503
    deadline = time.monotonic() + 70
    for model in gemini_models():
        left = deadline - time.monotonic()
        if left < 5:
            break
        try:
            out = _gemini_once(model, prompt, timeout=min(20, left))
            _gemini_good = model
            return out
        except urllib.error.HTTPError as e:
            last = e.code
            if e.code == 404:
                _gemini_model = None  # model retired: list them again next time
            elif e.code not in (429, 500, 503):
                raise HTTPException(502, f'Gemini error {e.code}')
        except (urllib.error.URLError, TimeoutError, OSError):
            last = 503  # no answer in time: overloaded, try the next model
        if model == _gemini_good:
            _gemini_good = None
    raise HTTPException(429 if last == 429 else 503, 'AI busy, try again in a minute')


def _gemini_once(model: str, prompt: str, timeout: float = 20) -> dict:
    payload = {
        'systemInstruction': {'parts': [{'text': SYSTEM}]},
        'contents': [{'role': 'user', 'parts': [{'text': prompt}]}],
        'generationConfig': {
            'responseMimeType': 'application/json',
            'responseSchema': {
                'type': 'OBJECT',
                'properties': {'title': {'type': 'STRING'}, 'body': {'type': 'STRING'}},
                'required': ['title', 'body'],
            },
        },
    }
    res = _gemini_call(f'models/{model}:generateContent', payload, timeout=timeout)
    try:
        text = ''.join(p.get('text', '') for p in res['candidates'][0]['content']['parts'])
        return json.loads(text)
    except (KeyError, IndexError, ValueError):
        raise HTTPException(422, 'The AI could not rewrite this text')


# --- Claude (Anthropic) ---------------------------------------------------------
def claude(prompt: str) -> dict:
    import anthropic

    client = anthropic.Anthropic(api_key=_key('ANTHROPIC_API_KEY'), timeout=120)
    try:
        response = client.beta.messages.parse(
            model=MODEL,
            max_tokens=16000,
            system=SYSTEM,
            messages=[{'role': 'user', 'content': prompt}],
            output_format=Rewrite,
            output_config={'effort': 'medium'},
            # A declined request is retried on Anthropic's recommended model.
            betas=['server-side-fallback-2026-07-01'],
            fallbacks='default',
        )
    except anthropic.RateLimitError:
        raise HTTPException(429, 'AI busy, try again in a minute')
    except anthropic.APIConnectionError:
        raise HTTPException(503, 'AI unreachable')
    except anthropic.APIStatusError as e:
        raise HTTPException(502, f'AI error {e.status_code}')
    if response.stop_reason == 'refusal' or response.parsed_output is None:
        raise HTTPException(422, 'The AI could not rewrite this text')
    return response.parsed_output.model_dump()
